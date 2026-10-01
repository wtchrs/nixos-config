package applications

import (
	"context"
	"fmt"
	"io"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"testing"
	"time"
)

var integrationBuild struct {
	sync.Once
	path string
	err  error
}

func integrationBinary(t *testing.T) string {
	t.Helper()
	integrationBuild.Do(func() {
		dir, err := os.MkdirTemp("/tmp", "wr-bin-")
		if err != nil {
			integrationBuild.err = err
			return
		}
		integrationBuild.path = filepath.Join(dir, "win-run")
		cmd := exec.Command("go", "build", "-race", "-o", integrationBuild.path, "./manager")
		moduleRoot, err := filepath.Abs("..")
		if err != nil {
			integrationBuild.err = err
			return
		}
		cmd.Dir = moduleRoot
		cmd.Env = append(os.Environ(), "GOWORK=off")
		if os.Getenv("GOCACHE") == "" {
			cmd.Env = append(cmd.Env, "GOCACHE=/tmp/win-run-go-cache")
		}
		out, err := cmd.CombinedOutput()
		if err != nil {
			integrationBuild.err = fmt.Errorf("build: %w\n%s", err, out)
		}
	})
	if integrationBuild.err != nil {
		t.Fatal(integrationBuild.err)
	}
	return integrationBuild.path
}

func TestMain(m *testing.M) {
	code := m.Run()
	if integrationBuild.path != "" {
		os.RemoveAll(filepath.Dir(integrationBuild.path))
	}
	os.Exit(code)
}

type integrationEnv struct {
	cfg  configuration
	env  []string
	root string
}

func newIntegrationEnv(t *testing.T) *integrationEnv {
	t.Helper()
	root, err := os.MkdirTemp("/tmp", "wr-")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { os.RemoveAll(root) })
	e := &integrationEnv{
		root: root,
		cfg: configuration{
			Prefix:     filepath.Join(root, "prefix"),
			DataHome:   filepath.Join(root, "data"),
			RuntimeDir: filepath.Join(root, "run", "win-run"),
			Executable: integrationBinary(t),
			Proton:     filepath.Join(root, "proton"),
			UMU:        filepath.Join(root, "umu"),
		},
	}
	for _, dir := range []string{filepath.Join(root, "home"), filepath.Join(root, "run"), e.cfg.Proton} {
		if err := os.MkdirAll(dir, 0700); err != nil {
			t.Fatal(err)
		}
	}
	overrides := map[string]string{
		"HOME":                    filepath.Join(root, "home"),
		"XDG_DATA_HOME":           e.cfg.DataHome,
		"XDG_RUNTIME_DIR":         filepath.Join(root, "run"),
		"WIN_RUN_WORKSPACE":       e.cfg.Prefix,
		"WIN_RUN_PROTON":          e.cfg.Proton,
		"WIN_RUN_UMU":             e.cfg.UMU,
		"WIN_RUN_STARTUP_TIMEOUT": "0",
		"WIN_RUN_LAUNCH_CLIENT":   filepath.Join(root, "no-client"),
	}
	for _, value := range os.Environ() {
		key, _, _ := strings.Cut(value, "=")
		if _, ok := overrides[key]; !ok {
			e.env = append(e.env, value)
		}
	}
	for key, value := range overrides {
		e.env = append(e.env, key+"="+value)
	}
	return e
}

// Poll only assertions, never shortcut discovery in the program under test.
func integrationEventually(t *testing.T, description string, check func() bool) {
	t.Helper()
	timer := time.NewTimer(8 * time.Second)
	defer timer.Stop()
	tick := time.NewTicker(10 * time.Millisecond)
	defer tick.Stop()
	for {
		if check() {
			return
		}
		select {
		case <-timer.C:
			t.Fatalf("timed out: %s", description)
		case <-tick.C:
		}
	}
}
func integrationExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}
func (e *integrationEnv) desktop(shortcut string) string {
	return filepath.Join(e.cfg.DataHome, "applications", "win-run-"+entryID(e.cfg.Prefix, shortcut)+".desktop")
}

type integrationProcess struct {
	cmd  *exec.Cmd
	done chan struct{}
	err  error
	log  string
}

func (e *integrationEnv) start(t *testing.T, args ...string) *integrationProcess {
	t.Helper()
	log, err := os.CreateTemp(e.root, "process-")
	if err != nil {
		t.Fatal(err)
	}
	p := &integrationProcess{
		cmd:  exec.Command(e.cfg.Executable, args...),
		done: make(chan struct{}),
		log:  log.Name(),
	}
	p.cmd.Env = e.env
	p.cmd.Stdout = log
	p.cmd.Stderr = log
	if err := p.cmd.Start(); err != nil {
		log.Close()
		t.Fatal(err)
	}
	go func() {
		p.err = p.cmd.Wait()
		log.Close()
		close(p.done)
	}()
	t.Cleanup(func() {
		select {
		case <-p.done:
			return
		default:
		}
		p.cmd.Process.Kill()
		select {
		case <-p.done:
		case <-time.After(8 * time.Second):
			t.Errorf("process did not exit")
		}
	})
	return p
}
func (p *integrationProcess) wait(t *testing.T, status int) {
	t.Helper()
	select {
	case <-p.done:
	case <-time.After(8 * time.Second):
		t.Fatal("CLI did not finish")
	}
	got := 0
	if p.err != nil {
		if exit, ok := p.err.(*exec.ExitError); ok {
			got = exit.ExitCode()
		} else {
			t.Fatal(p.err)
		}
	}
	if got != status {
		out, _ := os.ReadFile(p.log)
		t.Fatalf("exit %d, want %d: %s", got, status, out)
	}
}
func (p *integrationProcess) alive(t *testing.T) {
	t.Helper()
	select {
	case <-p.done:
		out, _ := os.ReadFile(p.log)
		t.Fatalf("CLI exited early: %v\n%s", p.err, out)
	default:
	}
}

// SO_PEERCRED identifies the daemon actually accepting this socket.
func (e *integrationEnv) owner(t *testing.T) (os.FileInfo, int) {
	t.Helper()
	var info os.FileInfo
	var pid int
	integrationEventually(t, "watcher accepting leases", func() bool {
		ctx, cancel := context.WithTimeout(context.Background(), 250*time.Millisecond)
		defer cancel()
		conn, err := connectWatcher(ctx, e.options())
		if err != nil {
			return false
		}
		defer conn.Close()
		raw, err := conn.(*net.UnixConn).SyscallConn()
		if err != nil {
			t.Fatal(err)
		}
		err = raw.Control(func(fd uintptr) {
			cred, err := syscall.GetsockoptUcred(int(fd), syscall.SOL_SOCKET, syscall.SO_PEERCRED)
			if err != nil {
				t.Fatal(err)
			}
			pid = int(cred.Pid)
		})
		if err != nil {
			t.Fatal(err)
		}
		info, err = os.Stat(e.options().socketPath())
		return err == nil
	})
	file, err := os.OpenFile(e.options().socketPath()+".owner.lock", os.O_RDWR, 0)
	if err != nil {
		t.Fatal(err)
	}
	defer file.Close()
	err = syscall.Flock(int(file.Fd()), syscall.LOCK_EX|syscall.LOCK_NB)
	if err == nil {
		syscall.Flock(int(file.Fd()), syscall.LOCK_UN)
		t.Fatal("daemon owner lock is not held")
	}
	if err != syscall.EWOULDBLOCK {
		t.Fatal(err)
	}
	command, err := os.ReadFile(filepath.Join("/proc", strconv.Itoa(pid), "cmdline"))
	if err != nil {
		t.Fatal(err)
	}
	if string(command) != e.cfg.Executable+"\x00_watcher\x00" {
		t.Fatalf("unexpected daemon: %q", command)
	}
	return info, pid
}
func (e *integrationEnv) stopped(t *testing.T) {
	t.Helper()
	integrationEventually(t, "last lease removes socket and releases owner lock", func() bool {
		if _, err := os.Stat(e.options().socketPath()); !os.IsNotExist(err) {
			return false
		}
		f, err := os.OpenFile(e.options().socketPath()+".owner.lock", os.O_RDWR, 0)
		if err != nil {
			return false
		}
		defer f.Close()
		if syscall.Flock(int(f.Fd()), syscall.LOCK_EX|syscall.LOCK_NB) != nil {
			return false
		}
		syscall.Flock(int(f.Fd()), syscall.LOCK_UN)
		return true
	})
}

func TestWatcherMissingPrefixAndDirectoryReplacement(t *testing.T) {
	e := newIntegrationEnv(t)
	if integrationExists(e.cfg.Prefix) {
		t.Fatal("prefix already exists")
	}
	watch := e.start(t, "watch")
	integrationEventually(t, "watch lease connected", func() bool { return processHasSocket(watch.cmd.Process.Pid) })
	e.owner(t)
	shortcut := `C:\Games\Later\Game.lnk`
	link := filepath.Join(e.cfg.Prefix, "drive_c", "Games", "Later", "Game.lnk")
	catalogTestCandidate(t, e.cfg, "game.desktop", "Game", shortcut, "")
	// A second completed handshake is a synchronization barrier for the candidate.
	e.owner(t)
	if integrationExists(e.desktop(shortcut)) {
		t.Fatal("registered missing shortcut")
	}
	catalogTestWrite(t, link, "shortcut")
	integrationEventually(t, "new shortcut registered", func() bool { return integrationExists(e.desktop(shortcut)) })
	if err := os.Remove(link); err != nil {
		t.Fatal(err)
	}
	integrationEventually(t, "removed shortcut unregistered", func() bool { return !integrationExists(e.desktop(shortcut)) })
	old := filepath.Join(e.cfg.Prefix, "drive_c", "Games")
	if err := os.Rename(old, old+".old"); err != nil {
		t.Fatal(err)
	}
	catalogTestWrite(t, link, "replacement")
	integrationEventually(t, "replacement directory registered", func() bool { return integrationExists(e.desktop(shortcut)) })
	if err := os.Remove(link); err != nil {
		t.Fatal(err)
	}
	integrationEventually(t, "replacement directory remains watched", func() bool { return !integrationExists(e.desktop(shortcut)) })
	watch.alive(t)
	watch.cmd.Process.Signal(syscall.SIGTERM)
	watch.wait(t, 0)
	e.stopped(t)
}

func TestWatcherSingletonAndAbruptLeaseRelease(t *testing.T) {
	e := newIntegrationEnv(t)
	e.blockingUMU(t)
	first := e.start(t, "watch")
	integrationEventually(t, "first watch lease connected", func() bool { return processHasSocket(first.cmd.Process.Pid) })
	before, pid := e.owner(t)
	second := e.start(t, "watch")
	// Wait for both real watch processes to hold a socket, not just for socket creation.
	integrationEventually(t, "two watch leases", func() bool {
		return processHasSocket(first.cmd.Process.Pid) && processHasSocket(second.cmd.Process.Pid)
	})
	open1 := e.start(t, "open", e.target(t, "one.exe"))
	e.waitStarted(t)
	after, other := e.owner(t)
	if !os.SameFile(before, after) || pid != other {
		t.Fatal("overlapping leases replaced daemon")
	}
	open2 := e.start(t, "open", e.target(t, "two.exe"))
	e.waitUMUCount(t, 2)
	after, other = e.owner(t)
	if !os.SameFile(before, after) || pid != other {
		t.Fatal("second open replaced daemon")
	}
	e.releaseUMU(t)
	open1.wait(t, 0)
	open2.wait(t, 0)
	first.alive(t)
	second.alive(t)
	after, other = e.owner(t)
	if !os.SameFile(before, after) || pid != other {
		t.Fatal("explicit watches lost daemon after opens finished")
	}
	first.cmd.Process.Kill()
	first.wait(t, -1)
	// Registration after the kill proves the surviving lease still drives inotify.
	shortcut := `C:\Games\Alive.lnk`
	catalogTestWrite(t, filepath.Join(e.cfg.Prefix, "drive_c", "Games", "Alive.lnk"), "")
	catalogTestCandidate(t, e.cfg, "alive.desktop", "Alive", shortcut, "")
	integrationEventually(t, "surviving lease registers shortcut", func() bool { return integrationExists(e.desktop(shortcut)) })
	second.cmd.Process.Kill()
	second.wait(t, -1)
	e.stopped(t)
}
func processHasSocket(pid int) bool {
	paths, _ := filepath.Glob(filepath.Join("/proc", strconv.Itoa(pid), "fd", "*"))
	for _, path := range paths {
		value, _ := os.Readlink(path)
		if strings.HasPrefix(value, "socket:[") {
			return true
		}
	}
	return false
}

func (e *integrationEnv) setEnv(key, value string) {
	for i, item := range e.env {
		if strings.HasPrefix(item, key+"=") {
			e.env[i] = key + "=" + value
			return
		}
	}
	e.env = append(e.env, key+"="+value)
}

func TestWatcherAbsentPrefixUnderSymlinkAlias(t *testing.T) {
	e := newIntegrationEnv(t)
	real := filepath.Join(e.root, "real")
	if err := os.Mkdir(real, 0700); err != nil {
		t.Fatal(err)
	}
	alias := filepath.Join(e.root, "alias")
	if err := os.Symlink(real, alias); err != nil {
		t.Fatal(err)
	}
	e.cfg.Prefix = filepath.Join(real, "not-created", "prefix")
	e.setEnv("WIN_RUN_WORKSPACE", filepath.Join(alias, "not-created", "prefix"))
	first := e.start(t, "watch")
	integrationEventually(t, "alias watch connected", func() bool { return processHasSocket(first.cmd.Process.Pid) })
	before, pid := e.owner(t)
	shortcut := `C:\Games\Alias.lnk`
	catalogTestWrite(t, filepath.Join(e.cfg.Prefix, "drive_c", "Games", "Alias.lnk"), "")
	catalogTestCandidate(t, e.cfg, "alias.desktop", "Alias", shortcut, "")
	integrationEventually(t, "alias prefix registered", func() bool { return integrationExists(e.desktop(shortcut)) })
	e.setEnv("WIN_RUN_WORKSPACE", e.cfg.Prefix)
	second := e.start(t, "watch")
	integrationEventually(t, "canonical watch connected", func() bool { return processHasSocket(second.cmd.Process.Pid) })
	after, other := e.owner(t)
	if !os.SameFile(before, after) || pid != other {
		t.Fatal("canonical path and initially absent alias used different daemons")
	}
	first.cmd.Process.Signal(syscall.SIGTERM)
	first.wait(t, 0)
	second.alive(t)
	e.owner(t)
	second.cmd.Process.Signal(syscall.SIGTERM)
	second.wait(t, 0)
	e.stopped(t)
}

func TestWatcherIndependentPrefixesSharingDataHome(t *testing.T) {
	first := newIntegrationEnv(t)
	second := newIntegrationEnv(t)
	second.cfg.DataHome = first.cfg.DataHome
	second.setEnv("XDG_DATA_HOME", first.cfg.DataHome)
	// Share the session runtime directory too: only prefix identity separates sockets.
	second.cfg.RuntimeDir = first.cfg.RuntimeDir
	second.setEnv("XDG_RUNTIME_DIR", filepath.Dir(first.cfg.RuntimeDir))
	shortcut := `C:\Games\Shared.lnk`
	for _, e := range []*integrationEnv{first, second} {
		catalogTestWrite(t, filepath.Join(e.cfg.Prefix, "drive_c", "Games", "Shared.lnk"), "")
		catalogTestCandidate(t, e.cfg, "shared.desktop", filepath.Base(e.root), shortcut, "")
	}
	one := first.start(t, "watch")
	two := second.start(t, "watch")
	integrationEventually(t, "independent watches connected", func() bool { return processHasSocket(one.cmd.Process.Pid) && processHasSocket(two.cmd.Process.Pid) })
	_, pid1 := first.owner(t)
	_, pid2 := second.owner(t)
	if pid1 == pid2 || first.options().socketPath() == second.options().socketPath() {
		t.Fatal("independent prefixes share daemon")
	}
	if first.desktop(shortcut) == second.desktop(shortcut) {
		t.Fatal("entry identity collides across prefixes")
	}
	integrationEventually(t, "both prefixes registered", func() bool {
		return integrationExists(first.desktop(shortcut)) && integrationExists(second.desktop(shortcut))
	})
	if err := os.Remove(filepath.Join(first.cfg.Prefix, "drive_c", "Games", "Shared.lnk")); err != nil {
		t.Fatal(err)
	}
	integrationEventually(t, "first prefix entry removed", func() bool { return !integrationExists(first.desktop(shortcut)) })
	if !integrationExists(second.desktop(shortcut)) {
		t.Fatal("first prefix synchronization removed second prefix entry")
	}
	one.cmd.Process.Signal(syscall.SIGTERM)
	one.wait(t, 0)
	first.stopped(t)
	two.alive(t)
	second.owner(t)
	if !integrationExists(second.desktop(shortcut)) {
		t.Fatal("first daemon shutdown removed second prefix entry")
	}
	two.cmd.Process.Signal(syscall.SIGTERM)
	two.wait(t, 0)
	second.stopped(t)
}

func TestWatcherMappedDriveMovedAwayAndBack(t *testing.T) {
	e := newIntegrationEnv(t)
	drive := filepath.Join(e.root, "mapped-drive")
	catalogTestWrite(t, filepath.Join(drive, "Apps", "Mapped.lnk"), "shortcut")
	mappings := filepath.Join(e.cfg.Prefix, "dosdevices")
	if err := os.MkdirAll(mappings, 0700); err != nil {
		t.Fatal(err)
	}
	indirect := filepath.Join(e.root, "indirect-drive")
	if err := os.Symlink(drive, indirect); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(indirect, filepath.Join(mappings, "d:")); err != nil {
		t.Fatal(err)
	}
	shortcut := `D:\Apps\Mapped.lnk`
	catalogTestCandidate(t, e.cfg, "mapped.desktop", "Mapped", shortcut, "")
	watch := e.start(t, "watch")
	integrationEventually(t, "mapped drive registered", func() bool { return integrationExists(e.desktop(shortcut)) })
	before, pid := e.owner(t)
	if err := os.Rename(drive, drive+".away"); err != nil {
		t.Fatal(err)
	}
	integrationEventually(t, "missing physical drive unregistered", func() bool { return !integrationExists(e.desktop(shortcut)) })
	watch.alive(t)
	if err := os.Rename(drive+".away", drive); err != nil {
		t.Fatal(err)
	}
	integrationEventually(t, "returned physical drive registered", func() bool { return integrationExists(e.desktop(shortcut)) })
	watch.alive(t)
	after, other := e.owner(t)
	if !os.SameFile(before, after) || pid != other {
		t.Fatal("mapped drive recovery replaced daemon")
	}
	if err := watch.cmd.Process.Signal(syscall.SIGTERM); err != nil {
		t.Fatal(err)
	}
	watch.wait(t, 0)
	e.stopped(t)
}

func TestWatcherMissingLowercaseDirectoryCreatedMixedCase(t *testing.T) {
	e := newIntegrationEnv(t)
	shortcut := `C:\games\mixedcase\Game.lnk`
	// Keep the candidate's ancestor present so the filtered watch has only the
	// lowercase missing child's spelling before the mixed-case creation event.
	if err := os.MkdirAll(filepath.Join(e.cfg.Prefix, "drive_c", "Games"), 0700); err != nil {
		t.Fatal(err)
	}
	catalogTestCandidate(t, e.cfg, "mixed.desktop", "Mixed Case", shortcut, "")
	watch := e.start(t, "watch")
	integrationEventually(t, "mixed-case watch connected", func() bool { return processHasSocket(watch.cmd.Process.Pid) })
	e.owner(t) // Completed synchronization establishes the missing-child watch.
	if integrationExists(e.desktop(shortcut)) {
		t.Fatal("registered missing shortcut")
	}
	link := filepath.Join(e.cfg.Prefix, "drive_c", "Games", "MixedCase", "Game.lnk")
	catalogTestWrite(t, link, "shortcut")
	integrationEventually(t, "mixed-case directory creation registered", func() bool { return integrationExists(e.desktop(shortcut)) })
	if err := os.Remove(link); err != nil {
		t.Fatal(err)
	}
	integrationEventually(t, "mixed-case directory remains watched", func() bool { return !integrationExists(e.desktop(shortcut)) })
	watch.alive(t)
	if err := watch.cmd.Process.Signal(syscall.SIGTERM); err != nil {
		t.Fatal(err)
	}
	watch.wait(t, 0)
	e.stopped(t)
}

func TestWatcherCancelledJoinAllowsNextLease(t *testing.T) {
	cfg := catalogTestConfig(t)
	shortcut := `C:\Games\Join.lnk`
	catalogTestWrite(t, filepath.Join(cfg.Prefix, "drive_c", "Games", "Join.lnk"), "shortcut")
	catalogTestCandidate(t, cfg, "join.desktop", "Before", shortcut, "")
	watcher, err := newDirectoryWatcher()
	if err != nil {
		t.Fatal(err)
	}
	defer watcher.Close()

	server, client := net.Pipe()
	defer server.Close()
	client.Close()
	accepted, err := acceptWatcherLease(cfg.options(), watcher, server)
	if accepted || err != nil {
		t.Fatalf("disconnected join: accepted=%v, error=%v", accepted, err)
	}
	desktop := filepath.Join(cfg.DataHome, "applications", "win-run-"+entryID(cfg.Prefix, shortcut)+".desktop")
	data, err := os.ReadFile(desktop)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(data), "Name="+escapeDesktopValue("win-run: Before")+"\n") {
		t.Fatalf("disconnected join did not synchronize: %s", data)
	}

	// Reuse the same inotify watcher and change the catalog before the next join.
	catalogTestCandidate(t, cfg, "join.desktop", "After", shortcut, "")
	nextServer, nextClient := net.Pipe()
	defer nextServer.Close()
	defer nextClient.Close()
	if err := nextClient.SetReadDeadline(time.Now().Add(2 * time.Second)); err != nil {
		t.Fatal(err)
	}
	ready := make(chan error, 1)
	go func() {
		var reply [1]byte
		_, err := io.ReadFull(nextClient, reply[:])
		if err == nil && reply[0] != 'R' {
			err = fmt.Errorf("readiness byte %q, want R", reply[0])
		}
		ready <- err
	}()
	accepted, err = acceptWatcherLease(cfg.options(), watcher, nextServer)
	if !accepted || err != nil {
		t.Fatalf("next join: accepted=%v, error=%v", accepted, err)
	}
	if err := <-ready; err != nil {
		t.Fatal(err)
	}
	data, err = os.ReadFile(desktop)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(data), "Name="+escapeDesktopValue("win-run: After")+"\n") {
		t.Fatalf("next join did not synchronize updated catalog: %s", data)
	}
}
