package runtime

import (
	"context"
	"crypto/md5"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"
	"time"
)

// Options describes only what UMU needs to run a program.
type Options struct {
	Prefix   string
	DataHome string
	Proton   string
	UMU      string
}

// Runner owns a validated runtime and the environment used by its processes.
// Shortcut registration and watcher leases belong to the caller.
type Runner struct {
	options     Options
	environment []string
}

// New validates the runtime and creates the selected prefix directory before
// the caller starts any watcher or Windows process.
func New(options Options) (*Runner, error) {
	environment, err := runtimeEnvironment(options)
	if err != nil {
		return nil, err
	}
	if err := os.MkdirAll(options.Prefix, 0700); err != nil {
		return nil, err
	}
	return &Runner{options: options, environment: environment}, nil
}

func runtimeEnvironment(cfg Options) ([]string, error) {
	info, err := os.Stat(cfg.Proton)
	if err != nil || !info.IsDir() {
		return nil, fmt.Errorf("Proton is not available at %s", cfg.Proton)
	}
	info, err = os.Stat(cfg.UMU)
	if err != nil || !info.Mode().IsRegular() || info.Mode().Perm()&0111 == 0 {
		return nil, fmt.Errorf("UMU launcher is not executable at %s", cfg.UMU)
	}
	values := map[string]string{
		"GAMEID": "win-run-default", "STORE": "none", "WINEPREFIX": cfg.Prefix,
		"PROTONPATH": cfg.Proton, "PROTON_VERB": "run", "UMU_CONTAINER_NSENTER": "1",
	}
	environment := make([]string, 0, len(os.Environ())+len(values))
	for _, value := range os.Environ() {
		key, _, _ := strings.Cut(value, "=")
		if _, replaced := values[key]; !replaced && key != "UMU_USE_STEAM" {
			environment = append(environment, value)
		}
	}
	for key, value := range values {
		environment = append(environment, key+"="+value)
	}
	return environment, nil
}

// Run executes UMU, preserves its exit status, and supervises its process group.
// Concurrent runs serialize prefix startup, not the lifetime of applications.
func (runner *Runner) Run(ctx context.Context, target string, args []string) (int, error) {
	cfg := runner.options
	startup, err := AcquireLock(ctx, filepath.Join(cfg.Prefix, ".win-run-startup.lock"))
	if err != nil {
		return 2, err
	}
	alreadyActive := runtimeServiceActive(ctx, cfg)
	if err := ctx.Err(); err != nil {
		startup.Close()
		return 2, err
	}
	cmd := exec.Command(cfg.UMU, append([]string{target}, args...)...)
	cmd.Env = runner.environment
	cmd.Stdin, cmd.Stdout, cmd.Stderr = os.Stdin, os.Stdout, os.Stderr
	cmd.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
	if err := cmd.Start(); err != nil {
		startup.Close()
		return 2, fmt.Errorf("could not start UMU: %w", err)
	}
	finished := make(chan struct{})
	var waitErr error
	go func() {
		waitErr = cmd.Wait()
		close(finished)
	}()
	supervised := make(chan struct{})
	go func() {
		defer close(supervised)
		select {
		case <-ctx.Done():
		case <-finished:
			if ctx.Err() == nil {
				return
			}
		}
		terminateProcessGroup(cmd.Process.Pid, finished)
	}()
	if !alreadyActive {
		waitForRuntimeStartup(ctx, cfg, finished)
	}
	startup.Close()
	<-finished
	<-supervised
	if waitErr == nil {
		return 0, nil
	}
	var exitErr *exec.ExitError
	if errors.As(waitErr, &exitErr) {
		status := exitErr.Sys().(syscall.WaitStatus)
		if status.Signaled() {
			return 128 + int(status.Signal()), nil
		}
		return exitErr.ExitCode(), nil
	}
	return 2, waitErr
}

func terminateProcessGroup(pid int, finished <-chan struct{}) {
	syscall.Kill(-pid, syscall.SIGTERM)
	grace := time.NewTimer(5 * time.Second)
	defer grace.Stop()
	select {
	case <-finished:
		// The launcher can exit before a child that ignored SIGTERM.
		// Keep the lease until its process group has been cleaned up.
		if syscall.Kill(-pid, 0) == nil {
			<-grace.C
			syscall.Kill(-pid, syscall.SIGKILL)
		}
	case <-grace.C:
		syscall.Kill(-pid, syscall.SIGKILL)
	}
}

func runtimeServiceActive(ctx context.Context, cfg Options) bool {
	clients := []string{}
	if override := os.Getenv("WIN_RUN_LAUNCH_CLIENT"); override != "" {
		clients = append(clients, override)
	} else {
		clients, _ = filepath.Glob(filepath.Join(cfg.DataHome, "umu", "*", "pressure-vessel", "bin", "steam-runtime-launch-client"))
	}
	// UMU derives the launcher service identity from the prefix path, not the
	// game ID. MD5 here mirrors that identifier; it is not a security digest.
	digest := md5.Sum([]byte(cfg.Prefix))
	expected := fmt.Sprintf("--bus-name=com.steampowered.App%x", digest)
	for _, client := range clients {
		probeCtx, cancel := context.WithTimeout(ctx, 2*time.Second)
		output, err := exec.CommandContext(probeCtx, client, "--list").Output()
		cancel()
		if err == nil {
			for _, line := range strings.Split(string(output), "\n") {
				if line == expected {
					return true
				}
			}
		}
	}
	return false
}

func waitForRuntimeStartup(ctx context.Context, cfg Options, finished <-chan struct{}) {
	seconds, err := strconv.ParseFloat(startupTimeout(), 64)
	if err != nil || seconds <= 0 {
		return
	}
	deadlineCtx, cancel := context.WithTimeout(ctx, time.Duration(seconds*float64(time.Second)))
	defer cancel()
	// These bounded service-readiness probes preserve concurrent UMU startup
	// behavior. They do not inspect or poll shortcut files.
	probe := time.NewTicker(100 * time.Millisecond)
	defer probe.Stop()
	for {
		select {
		case <-finished:
			return
		case <-deadlineCtx.Done():
			return
		case <-probe.C:
			if runtimeServiceActive(deadlineCtx, cfg) {
				return
			}
		}
	}
}

func startupTimeout() string {
	if value := os.Getenv("WIN_RUN_STARTUP_TIMEOUT"); value != "" {
		return value
	}
	return "15"
}
