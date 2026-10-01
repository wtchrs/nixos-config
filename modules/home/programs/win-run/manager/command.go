package main

import (
	"context"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"win-run/applications"
	"win-run/runtime"
)

var entryIDPattern = regexp.MustCompile(`^wr1-[0-9a-f]{24}$`)

const launchUsage = "usage: win-run launch <entry-id> [--prefix <absolute-path>]"
const usage = `usage: win-run open <file.exe|file.msi> [-- <arguments>...]
       win-run launch <entry-id> [--prefix <absolute-path>]
       win-run watch`

// run dispatches one command using runtime defaults supplied by the executable.
func run(ctx context.Context, args []string, defaultProton, defaultUMU string) (int, error) {
	if len(args) == 1 && (args[0] == "--help" || args[0] == "-h") {
		fmt.Println(usage)
		return 0, nil
	}
	if len(args) == 0 {
		return 2, errors.New(usage)
	}
	settings, err := loadSettings(defaultProton, defaultUMU)
	if err != nil {
		return 2, err
	}
	switch args[0] {
	case "open":
		target, extra, err := openTarget(args[1:])
		if err != nil {
			return 2, err
		}
		return execute(ctx, settings, target, extra)
	case "launch":
		target, err := launchTarget(&settings, args[1:])
		if err != nil {
			return 2, err
		}
		return execute(ctx, settings, target, nil)
	case "watch":
		if len(args) != 1 {
			return 2, errors.New("usage: win-run watch")
		}
		return holdWatcher(ctx, watcherOptions(settings))
	case "_watcher":
		if len(args) != 1 {
			return 2, errors.New("invalid watcher invocation")
		}
		return 0, applications.ServeWatcher(ctx, watcherOptions(settings))
	default:
		return 2, fmt.Errorf("unknown command: %s\n%s", args[0], usage)
	}
}

func openTarget(args []string) (string, []string, error) {
	if len(args) == 0 {
		return "", nil, errors.New("usage: win-run open <file.exe|file.msi> [-- <arguments>...]")
	}
	extra := args[1:]
	if len(extra) > 0 {
		if extra[0] != "--" {
			return "", nil, errors.New("arguments for the Windows program must follow --")
		}
		extra = extra[1:]
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return "", nil, err
	}
	target, err := applications.AbsolutePath(args[0], home)
	if err != nil {
		return "", nil, err
	}
	info, err := os.Stat(target)
	if err != nil || !info.Mode().IsRegular() {
		return "", nil, fmt.Errorf("target does not exist or is not a regular file: %s", target)
	}
	extension := strings.ToLower(filepath.Ext(target))
	if extension != ".exe" && extension != ".msi" {
		return "", nil, fmt.Errorf("unsupported file type: %s", extension)
	}
	return target, extra, nil
}

func launchTarget(settings *settings, args []string) (string, error) {
	if (len(args) != 1 && len(args) != 3) || !entryIDPattern.MatchString(args[0]) {
		return "", errors.New(launchUsage)
	}
	// Generated entries retain their prefix even if the shell does not inherit
	// the environment override used when installing the application.
	if len(args) == 3 {
		if args[1] != "--prefix" || !filepath.IsAbs(args[2]) {
			return "", errors.New("launch --prefix requires an absolute prefix path")
		}
		prefix, err := applications.CanonicalPath(args[2])
		if err != nil {
			return "", err
		}
		settings.Prefix = prefix
	}
	entries, err := applications.Scan(settings.Prefix)
	if err != nil {
		return "", err
	}
	for _, item := range entries {
		if item.ID == args[0] {
			return item.Shortcut, nil
		}
	}
	return "", fmt.Errorf("unknown entry ID: %s", args[0])
}

func watcherOptions(settings settings) applications.WatcherOptions {
	return applications.WatcherOptions{
		Prefix:     settings.Prefix,
		DataHome:   settings.DataHome,
		RuntimeDir: settings.RuntimeDir,
		Executable: settings.Executable,
	}
}

func holdWatcher(ctx context.Context, options applications.WatcherOptions) (int, error) {
	lease, err := applications.AcquireWatcher(ctx, options)
	if err != nil {
		return 2, err
	}
	select {
	case <-ctx.Done():
		return 0, lease.Close()
	case <-lease.Done():
		return 2, errors.New("shortcut watcher exited unexpectedly")
	}
}

func execute(ctx context.Context, settings settings, target string, args []string) (int, error) {
	runner, err := runtime.New(runtime.Options{
		Prefix:   settings.Prefix,
		DataHome: settings.DataHome,
		Proton:   settings.Proton,
		UMU:      settings.UMU,
	})
	if err != nil {
		return 2, err
	}
	lease, err := applications.AcquireWatcher(ctx, watcherOptions(settings))
	if err != nil {
		return 2, err
	}
	defer func() {
		if err := lease.Close(); err != nil {
			fmt.Fprintln(os.Stderr, "win-run: final shortcut synchronization:", err)
		}
	}()
	// Watcher failure affects menu updates, not the Windows application's
	// lifetime or its exit status. UMU owns process supervision independently.
	finished := make(chan struct{})
	defer close(finished)
	go func() {
		select {
		case <-lease.Done():
			fmt.Fprintln(os.Stderr, "win-run: shortcut watcher exited; application execution continues")
		case <-finished:
		}
	}()
	return runner.Run(ctx, target, args)
}
