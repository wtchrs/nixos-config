package applications

import (
	"bytes"
	"encoding/binary"
	"errors"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"syscall"
)

// directoryWatcher blocks in the Go runtime's poller on an inotify descriptor.
// There is no periodic scan. The only timer elsewhere coalesces received events.
type directoryWatcher struct {
	file    *os.File
	watches map[string]int
	mu      sync.RWMutex
	filters map[int]watchFilter
	changed chan struct{}
	errors  chan error
	done    chan struct{}
}

type watchFilter struct {
	all      bool
	children map[string]bool
}

func (filter watchFilter) matches(name string) bool {
	if filter.all || filter.children[name] {
		return true
	}
	for child := range filter.children {
		if strings.EqualFold(child, name) {
			return true
		}
	}
	return false
}

func newDirectoryWatcher() (*directoryWatcher, error) {
	fd, err := syscall.InotifyInit1(syscall.IN_CLOEXEC | syscall.IN_NONBLOCK)
	if err != nil {
		return nil, err
	}
	w := &directoryWatcher{
		file: os.NewFile(uintptr(fd), "win-run-inotify"), watches: make(map[string]int),
		filters: make(map[int]watchFilter),
		changed: make(chan struct{}, 1), errors: make(chan error, 1), done: make(chan struct{}),
	}
	go w.readEvents()
	return w, nil
}

func (w *directoryWatcher) Close() error {
	err := w.file.Close()
	<-w.done
	return err
}

func (w *directoryWatcher) readEvents() {
	defer close(w.done)
	buffer := make([]byte, 64*1024)
	for {
		n, err := w.file.Read(buffer)
		if err != nil {
			if !errors.Is(err, os.ErrClosed) {
				w.errors <- err
			}
			return
		}
		// IN_IGNORED also follows our own watch removals. Ignore it to avoid
		// a feedback loop; deletion/move events already trigger reconciliation.
		changed := false
		for offset := 0; offset+syscall.SizeofInotifyEvent <= n; {
			wd := int(int32(binary.NativeEndian.Uint32(buffer[offset : offset+4])))
			mask := binary.NativeEndian.Uint32(buffer[offset+4 : offset+8])
			length := binary.NativeEndian.Uint32(buffer[offset+12 : offset+16])
			end := offset + syscall.SizeofInotifyEvent + int(length)
			if end > n {
				w.errors <- errors.New("truncated inotify event")
				return
			}
			name := string(bytes.TrimRight(buffer[offset+syscall.SizeofInotifyEvent:end], "\x00"))
			w.mu.RLock()
			filter, known := w.filters[wd]
			w.mu.RUnlock()
			const structural = syscall.IN_DELETE_SELF | syscall.IN_MOVE_SELF | syscall.IN_UNMOUNT
			if mask&syscall.IN_Q_OVERFLOW != 0 || (known && (mask&structural != 0 ||
				(mask & ^uint32(syscall.IN_IGNORED) != 0 && filter.matches(name)))) {
				changed = true
			}
			offset = end
		}
		if changed {
			select {
			case w.changed <- struct{}{}:
			default:
			}
		}
	}
}

func expandedWatchPaths(cfg WatcherOptions) ([]string, error) {
	directories, err := watchPaths(cfg.Prefix)
	if err != nil {
		return nil, err
	}
	// Wine drive mappings are symlinks. Also watch their physical ancestry:
	// moving a mapped drive away and back happens outside the prefix tree.
	mappings, err := os.ReadDir(filepath.Join(cfg.Prefix, "dosdevices"))
	if err != nil && !errors.Is(err, fs.ErrNotExist) {
		return nil, err
	}
	requested := append([]string(nil), directories...)
	for _, mapping := range mappings {
		if mapping.Type()&os.ModeSymlink == 0 {
			continue
		}
		link := filepath.Join(cfg.Prefix, "dosdevices", mapping.Name())
		target, err := os.Readlink(link)
		if err != nil {
			if errors.Is(err, fs.ErrNotExist) {
				continue
			}
			return nil, err
		}
		if !filepath.IsAbs(target) {
			target = filepath.Join(filepath.Dir(link), target)
		}
		for _, path := range requested {
			if path == link || strings.HasPrefix(path, link+string(filepath.Separator)) {
				suffix := strings.TrimPrefix(strings.TrimPrefix(path, link), string(filepath.Separator))
				directories = append(directories, filepath.Join(target, suffix))
			}
		}
	}
	for _, path := range directories {
		if resolved, err := CanonicalPath(path); err == nil && resolved != path {
			directories = append(directories, resolved)
		}
	}
	return directories, nil
}

func desiredWatchFilters(paths []string) (map[string]watchFilter, error) {
	desired := make(map[string]watchFilter)
	for _, path := range paths {
		// Watching every existing ancestor handles an entire subtree being
		// renamed/replaced, as well as a prefix not created yet by Proton.
		child := ""
		for {
			info, err := os.Stat(path)
			if err == nil && info.IsDir() {
				filter := desired[path]
				if child == "" {
					filter.all = true
				} else {
					if filter.children == nil {
						filter.children = make(map[string]bool)
					}
					filter.children[child] = true
				}
				desired[path] = filter
			} else if err != nil && !errors.Is(err, fs.ErrNotExist) {
				return nil, err
			}
			parent := filepath.Dir(path)
			if parent == path {
				break
			}
			child, path = filepath.Base(path), parent
		}
	}
	return desired, nil
}

func (w *directoryWatcher) refresh(cfg WatcherOptions) error {
	paths, err := expandedWatchPaths(cfg)
	if err != nil {
		return err
	}
	desired, err := desiredWatchFilters(paths)
	if err != nil {
		return err
	}
	return w.replaceWatches(desired)
}

func (w *directoryWatcher) replaceWatches(desired map[string]watchFilter) error {
	const mask = syscall.IN_CREATE | syscall.IN_CLOSE_WRITE | syscall.IN_DELETE |
		syscall.IN_MOVED_FROM | syscall.IN_MOVED_TO | syscall.IN_DELETE_SELF |
		syscall.IN_MOVE_SELF | syscall.IN_ATTRIB | syscall.IN_ONLYDIR
	// Re-adding a live watch updates its mask; re-adding a replaced directory
	// obtains a new descriptor. Only the event loop accesses this map.
	newWatches := make(map[string]int)
	newFilters := make(map[int]watchFilter)
	used := make(map[int]bool)
	w.mu.Lock()
	defer w.mu.Unlock()
	for path, filter := range desired {
		wd, err := syscall.InotifyAddWatch(int(w.file.Fd()), path, mask)
		if errors.Is(err, fs.ErrNotExist) {
			continue // It changed during the scan; an ancestor event is queued.
		}
		if err != nil {
			return fmt.Errorf("watch %s: %w", path, err)
		}
		newWatches[path] = wd
		// Different symlink paths can refer to the same watched inode.
		previous := newFilters[wd]
		filter.all = filter.all || previous.all
		if filter.children == nil {
			filter.children = make(map[string]bool)
		}
		for name := range previous.children {
			filter.children[name] = true
		}
		newFilters[wd] = filter
		used[wd] = true
	}
	for _, wd := range w.watches {
		if !used[wd] {
			syscall.InotifyRmWatch(int(w.file.Fd()), uint32(wd))
		}
	}
	w.watches = newWatches
	w.filters = newFilters
	return nil
}

func (w *directoryWatcher) synchronize(cfg WatcherOptions) error {
	// Watch first, scan second, then include directories found by that scan.
	// Changes during discovery are queued and cause another event-driven scan.
	if err := w.refresh(cfg); err != nil {
		return err
	}
	if err := (Registry{Prefix: cfg.Prefix, DataHome: cfg.DataHome, Executable: cfg.Executable}).Sync(); err != nil {
		return err
	}
	return w.refresh(cfg)
}
