package applications

import (
	"context"
	"crypto/sha256"
	"errors"
	"fmt"
	"io"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"syscall"
	"time"

	winruntime "win-run/runtime"
)

// WatcherOptions identifies the shortcut registry and daemon executable.
type WatcherOptions struct {
	Prefix     string
	DataHome   string
	RuntimeDir string
	Executable string
}

const watcherTimeout = 20 * time.Second

// A live socket connection is a lease. EOF releases it even after SIGKILL,
// without PID files or counters that can survive their owning process.
type Lease struct {
	conn   net.Conn
	result chan error
	failed chan struct{}
}

func (lease *Lease) Close() error {
	defer lease.conn.Close()
	lease.conn.SetDeadline(time.Now().Add(watcherTimeout))
	if _, err := lease.conn.Write([]byte{'Q'}); err != nil {
		return err
	}
	return <-lease.result
}

func AcquireWatcher(ctx context.Context, cfg WatcherOptions) (*Lease, error) {
	if err := os.MkdirAll(cfg.RuntimeDir, 0700); err != nil {
		return nil, err
	}
	gate, err := winruntime.AcquireLock(ctx, cfg.socketPath()+".start.lock")
	if err != nil {
		return nil, err
	}
	defer gate.Close()
	// A daemon may be completing its final sync when we connect. Its lifetime
	// lock ensures a replacement waits until the previous owner is gone.
	for attempt := 0; attempt < 3; attempt++ {
		conn, err := connectWatcher(ctx, cfg)
		if err == nil {
			lease := &Lease{conn: conn, result: make(chan error, 1), failed: make(chan struct{})}
			go func() {
				var reply [1]byte
				_, err := io.ReadFull(conn, reply[:])
				if err == nil && reply[0] != 'A' {
					err = errors.New("watcher final synchronization failed")
				}
				lease.result <- err
				close(lease.failed)
			}()
			return lease, nil
		}
		if ctx.Err() != nil {
			return nil, ctx.Err()
		}
		if err := startWatcher(ctx, cfg); err != nil {
			return nil, err
		}
	}
	return nil, errors.New("could not connect to shortcut watcher")
}

func connectWatcher(ctx context.Context, cfg WatcherOptions) (net.Conn, error) {
	dialer := net.Dialer{Timeout: watcherTimeout}
	conn, err := dialer.DialContext(ctx, "unix", cfg.socketPath())
	if err != nil {
		return nil, err
	}
	conn.SetDeadline(time.Now().Add(watcherTimeout))
	stopClosing := context.AfterFunc(ctx, func() { conn.Close() })
	defer stopClosing()
	var ready [1]byte
	if _, err = io.ReadFull(conn, ready[:]); err != nil || ready[0] != 'R' {
		conn.Close()
		if err == nil {
			err = errors.New("watcher initialization failed")
		}
		return nil, err
	}
	conn.SetDeadline(time.Time{})
	return conn, nil
}

func startWatcher(ctx context.Context, cfg WatcherOptions) error {
	reader, writer, err := os.Pipe()
	if err != nil {
		return err
	}
	defer reader.Close()
	stopClosing := context.AfterFunc(ctx, func() { reader.Close() })
	defer stopClosing()
	cmd := exec.Command(cfg.Executable, "_watcher")
	cmd.Env = append(os.Environ(), "WIN_RUN_WORKSPACE="+cfg.Prefix, "XDG_DATA_HOME="+cfg.DataHome)
	cmd.ExtraFiles = []*os.File{writer} // Descriptor 3 is a one-shot readiness pipe.
	cmd.Stderr = os.Stderr
	cmd.SysProcAttr = &syscall.SysProcAttr{Setsid: true}
	err = cmd.Start()
	writer.Close()
	if err != nil {
		return err
	}
	go cmd.Wait()
	reader.SetReadDeadline(time.Now().Add(watcherTimeout))
	var ready [1]byte
	if _, err := io.ReadFull(reader, ready[:]); err != nil || ready[0] != 'R' {
		cmd.Process.Kill()
		return fmt.Errorf("shortcut watcher did not become ready: %v", err)
	}
	return nil
}

type leaseEvent struct {
	conn    net.Conn
	joining bool
	ack     bool
	ready   chan bool
}

func ServeWatcher(ctx context.Context, cfg WatcherOptions) error {
	owner, err := winruntime.AcquireLock(ctx, cfg.socketPath()+".owner.lock")
	if err != nil {
		return err
	}
	defer owner.Close()
	// Only the owner of the lifetime lock may replace a stale socket.
	if err := os.Remove(cfg.socketPath()); err != nil && !errors.Is(err, os.ErrNotExist) {
		return err
	}
	listener, err := net.Listen("unix", cfg.socketPath())
	if err != nil {
		return err
	}
	defer listener.Close()
	watcher, err := newDirectoryWatcher()
	if err != nil {
		return err
	}
	defer watcher.Close()
	if err := watcher.synchronize(cfg); err != nil {
		return err
	}
	ready := os.NewFile(3, "watcher-readiness")
	if _, err := ready.Write([]byte{'R'}); err != nil {
		ready.Close()
		return err
	}
	ready.Close()

	events := make(chan leaseEvent)
	acceptErrors := make(chan error, 1)
	workerCtx, cancel := context.WithCancel(ctx)
	defer cancel()
	go acceptLeases(workerCtx, listener, events, acceptErrors)
	clients := make(map[net.Conn]bool)
	defer func() {
		for conn := range clients {
			conn.Close()
		}
	}()
	// A parent can die between spawning us and opening its lease. This is a
	// one-shot startup timeout, not a filesystem polling interval.
	orphan := time.NewTimer(watcherTimeout)
	defer orphan.Stop()
	debounce := time.NewTimer(time.Hour)
	debounce.Stop()
	defer debounce.Stop()
	var pending <-chan time.Time
	for {
		select {
		case <-ctx.Done():
			return watcher.synchronize(cfg)
		case <-orphan.C:
			if len(clients) == 0 {
				return watcher.synchronize(cfg)
			}
		case err := <-acceptErrors:
			return err
		case err := <-watcher.errors:
			return err
		case <-watcher.changed:
			// Cap the delay from the first event so continuous writes cannot
			// postpone registration indefinitely.
			if pending == nil {
				debounce.Reset(100 * time.Millisecond)
				pending = debounce.C
			}
		case <-pending:
			pending = nil
			if err := watcher.synchronize(cfg); err != nil {
				return err
			}
		case event := <-events:
			if event.joining {
				accepted, err := acceptWatcherLease(cfg, watcher, event.conn)
				if err != nil || !accepted {
					event.ready <- false
					event.conn.Close()
					if err != nil {
						return err
					}
					continue
				}
				clients[event.conn] = true
				orphan.Stop()
				event.ready <- true
				continue
			}
			delete(clients, event.conn)
			err := watcher.synchronize(cfg)
			if len(clients) == 0 {
				// Reject new joins before acknowledging the last release. The
				// replacement daemon waits for our owner lock to be released.
				listener.Close()
			}
			if event.ack {
				reply := byte('A')
				if err != nil {
					reply = 'E'
				}
				event.conn.SetWriteDeadline(time.Now().Add(watcherTimeout))
				event.conn.Write([]byte{reply})
			}
			event.conn.Close()
			if err != nil || len(clients) == 0 {
				return err
			}
		}
	}
}

func acceptWatcherLease(cfg WatcherOptions, watcher *directoryWatcher, conn net.Conn) (bool, error) {
	if err := watcher.synchronize(cfg); err != nil {
		return false, err
	}
	conn.SetWriteDeadline(time.Now().Add(watcherTimeout))
	_, err := conn.Write([]byte{'R'})
	conn.SetWriteDeadline(time.Time{})
	// A joining client can be cancelled while discovery is running. Its
	// disconnected transport must not terminate other clients' shared watcher.
	return err == nil, nil
}

func acceptLeases(ctx context.Context, listener net.Listener, events chan<- leaseEvent, failures chan<- error) {
	for {
		conn, err := listener.Accept()
		if err != nil {
			select {
			case failures <- err:
			case <-ctx.Done():
			}
			return
		}
		go func() {
			ready := make(chan bool, 1)
			select {
			case events <- leaseEvent{conn: conn, joining: true, ready: ready}:
			case <-ctx.Done():
				conn.Close()
				return
			}
			select {
			case ok := <-ready:
				if !ok {
					return
				}
			case <-ctx.Done():
				conn.Close()
				return
			}
			var request [1]byte
			_, err := io.ReadFull(conn, request[:])
			select {
			case events <- leaseEvent{conn: conn, ack: err == nil && request[0] == 'Q'}:
			case <-ctx.Done():
				conn.Close()
			}
		}()
	}
}

func (cfg WatcherOptions) socketPath() string {
	identity := sha256.Sum256([]byte(cfg.Prefix + "\x00" + cfg.DataHome))
	return filepath.Join(cfg.RuntimeDir, fmt.Sprintf("%x.sock", identity[:12]))
}

// Done closes when the daemon connection finishes or fails.
func (lease *Lease) Done() <-chan struct{} { return lease.failed }
