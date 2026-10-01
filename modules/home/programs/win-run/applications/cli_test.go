package applications

import (
	"os"
	"path/filepath"
	"reflect"
	"strconv"
	"strings"
	"syscall"
	"testing"
)

func (e *integrationEnv) script(t *testing.T, body string) {
	t.Helper()
	catalogTestWrite(t, e.cfg.UMU, "#!/bin/sh\nset -eu\n"+body)
	if err := os.Chmod(e.cfg.UMU, 0700); err != nil {
		t.Fatal(err)
	}
}
func (e *integrationEnv) target(t *testing.T, name string) string {
	t.Helper()
	path := filepath.Join(e.root, name)
	catalogTestWrite(t, path, "executable")
	return path
}
func (e *integrationEnv) blockingUMU(t *testing.T) {
	t.Helper()
	fifo := filepath.Join(e.root, "release")
	if err := syscall.Mkfifo(fifo, 0600); err != nil {
		t.Fatal(err)
	}
	f, err := os.OpenFile(fifo, os.O_RDWR, 0)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { f.Close() })
	e.env = append(e.env, "TEST_ROOT="+e.root)
	e.script(t, `printf '%s' "$$" > "$TEST_ROOT/started-$$"
IFS= read -r release < "$TEST_ROOT/release"
`)
	t.Cleanup(func() { f.WriteString("finish\nfinish\n") })
}
func (e *integrationEnv) waitUMUCount(t *testing.T, n int) {
	t.Helper()
	integrationEventually(t, "UMU processes started", func() bool {
		paths, err := filepath.Glob(filepath.Join(e.root, "started-*"))
		if err != nil {
			t.Fatal(err)
		}
		return len(paths) == n
	})
}
func (e *integrationEnv) waitStarted(t *testing.T) {
	t.Helper()
	e.waitUMUCount(t, 1)
}
func (e *integrationEnv) releaseUMU(t *testing.T) {
	t.Helper()
	f, err := os.OpenFile(filepath.Join(e.root, "release"), os.O_RDWR, 0)
	if err != nil {
		t.Fatal(err)
	}
	defer f.Close()
	if _, err := f.WriteString("finish\nfinish\n"); err != nil {
		t.Fatal(err)
	}
}

func TestRuntimeCLIArgumentsEnvironmentAndStatus(t *testing.T) {
	for _, tc := range []struct {
		name, ending string
		status       int
	}{{"exe", "exit 37\n", 37}, {"msi", "kill -TERM $$\n", 143}} {
		t.Run(tc.name, func(t *testing.T) {
			e := newIntegrationEnv(t)
			e.env = append(e.env, "TEST_ROOT="+e.root, "UMU_USE_STEAM=1", "GAMEID=wrong", "STORE=wrong", "WINEPREFIX=wrong", "PROTONPATH=wrong", "PROTON_VERB=wrong", "UMU_CONTAINER_NSENTER=wrong", "TEST_PASSTHROUGH=한글")
			e.script(t, `printf '%s\000' "$@" > "$TEST_ROOT/argv"
printf '%s\000' "$GAMEID" "$STORE" "$WINEPREFIX" "$PROTONPATH" "$PROTON_VERB" "$UMU_CONTAINER_NSENTER" "${UMU_USE_STEAM-unset}" "$TEST_PASSTHROUGH" > "$TEST_ROOT/env"
`+tc.ending)
			target := e.target(t, "한 글 'quoted' \"program\"."+strings.ToUpper(tc.name))
			args := []string{"", "two words", "한글 ☃", `single' double" slash\`, "$HOME; `echo bad`", "--flag", "line\nbreak"}
			p := e.start(t, append([]string{"open", target, "--"}, args...)...)
			p.wait(t, tc.status)
			e.stopped(t)
			read := func(name string) []string {
				data, err := os.ReadFile(filepath.Join(e.root, name))
				if err != nil {
					t.Fatal(err)
				}
				if len(data) == 0 || data[len(data)-1] != 0 {
					t.Fatalf("missing NUL terminator: %q", data)
				}
				return strings.Split(string(data[:len(data)-1]), "\x00")
			}
			if got, want := read("argv"), append([]string{target}, args...); !reflect.DeepEqual(got, want) {
				t.Fatalf("argv %q, want %q", got, want)
			}
			want := []string{"win-run-default", "none", e.cfg.Prefix, e.cfg.Proton, "run", "1", "unset", "한글"}
			if got := read("env"); !reflect.DeepEqual(got, want) {
				t.Fatalf("environment %q, want %q", got, want)
			}
			files, err := os.ReadDir(filepath.Join(e.cfg.DataHome, "applications"))
			if err != nil {
				t.Fatal(err)
			}
			if len(files) != 0 {
				t.Fatalf("portable executable registered: %v", files)
			}
		})
	}
}

func TestRuntimeInstallerRegistersBeforeExitAndLaunchesShortcut(t *testing.T) {
	e := newIntegrationEnv(t)
	e.blockingUMU(t)
	p := e.start(t, "open", e.target(t, "setup.exe"))
	e.waitStarted(t)
	shortcut := `C:\Games\Installed.lnk`
	catalogTestWrite(t, filepath.Join(e.cfg.Prefix, "drive_c", "Games", "Installed.lnk"), "installed")
	catalogTestCandidate(t, e.cfg, "installed.desktop", "Installed 게임", shortcut, "")
	integrationEventually(t, "installer shortcut registered while UMU is active", func() bool { return integrationExists(e.desktop(shortcut)) })
	p.alive(t)
	data, err := os.ReadFile(e.desktop(shortcut))
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(data), "Exec="+execArgument(e.cfg.Executable)+" launch "+entryID(e.cfg.Prefix, shortcut)+" --prefix "+execArgument(e.cfg.Prefix)+"\n") {
		t.Fatalf("invalid launch command: %s", data)
	}
	e.releaseUMU(t)
	p.wait(t, 0)
	e.stopped(t)
	e.script(t, `printf '%s\000' "$@" > "$TEST_ROOT/launched"
exit 19
`)
	e.setEnv("WIN_RUN_WORKSPACE", filepath.Join(e.root, "unrelated-prefix"))
	launch := e.start(t, "launch", entryID(e.cfg.Prefix, shortcut), "--prefix", e.cfg.Prefix)
	launch.wait(t, 19)
	e.stopped(t)
	got, err := os.ReadFile(filepath.Join(e.root, "launched"))
	if err != nil {
		t.Fatal(err)
	}
	if string(got) != shortcut+"\x00" {
		t.Fatalf("launch arguments: %q", got)
	}
}

func TestRuntimeCLIRejectsInvalidTargetsAndArgumentBoundary(t *testing.T) {
	e := newIntegrationEnv(t)
	e.env = append(e.env, "TEST_ROOT="+e.root)
	e.script(t, `touch "$TEST_ROOT/unexpected-umu"
`)
	valid := e.target(t, "valid.exe")
	unsupported := e.target(t, "invalid.txt")
	for _, args := range [][]string{{"open"}, {"open", valid, "unseparated"}, {"open", filepath.Join(e.root, "missing.exe")}, {"open", e.root}, {"open", unsupported}, {"launch", "invalid-id"}, {"launch", "wr1-000000000000000000000000"}} {
		t.Run(strings.Join(args, " "), func(t *testing.T) { e.start(t, args...).wait(t, 2) })
	}
	if integrationExists(filepath.Join(e.root, "unexpected-umu")) || integrationExists(e.options().socketPath()) {
		t.Fatal("invalid CLI started runtime or watcher")
	}
}

func TestRuntimeCancellationWhileStartupLockHeld(t *testing.T) {
	e := newIntegrationEnv(t)
	e.setEnv("TEST_ROOT", e.root)
	e.script(t, `printf 'started' > "$TEST_ROOT/unexpected-umu"
`)
	path := filepath.Join(e.cfg.Prefix, ".win-run-startup.lock")
	catalogTestWrite(t, path, "")
	lock, err := os.OpenFile(path, os.O_RDWR, 0)
	if err != nil {
		t.Fatal(err)
	}
	defer lock.Close()
	if err := syscall.Flock(int(lock.Fd()), syscall.LOCK_EX|syscall.LOCK_NB); err != nil {
		t.Fatal(err)
	}
	defer syscall.Flock(int(lock.Fd()), syscall.LOCK_UN)
	p := e.start(t, "open", e.target(t, "blocked.exe"))
	// Observe the kernel's blocked flock request before cancelling the CLI.
	integrationEventually(t, "CLI waiting for startup lock", func() bool {
		data, err := os.ReadFile("/proc/locks")
		if err != nil {
			t.Fatal(err)
		}
		for _, line := range strings.Split(string(data), "\n") {
			fields := strings.Fields(line)
			for i, field := range fields {
				if field == "WRITE" && i+1 < len(fields) && fields[i+1] == strconv.Itoa(p.cmd.Process.Pid) && strings.Contains(line, "->") {
					return true
				}
			}
		}
		return false
	})
	p.alive(t)
	if err := p.cmd.Process.Signal(syscall.SIGTERM); err != nil {
		t.Fatal(err)
	}
	// The holder deliberately remains locked until after the child has exited.
	p.wait(t, 2)
	if integrationExists(filepath.Join(e.root, "unexpected-umu")) {
		t.Fatal("cancelled startup launched UMU")
	}
	output, err := os.ReadFile(p.log)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(output), "context canceled") {
		t.Fatalf("missing cancellation error: %s", output)
	}
	e.stopped(t)
}
