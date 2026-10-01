package main

import (
	"fmt"
	"os"
	"path/filepath"

	"win-run/applications"
)

// settings holds resolved session paths and runtime choices. Each consumer
// receives only the fields relevant to its own responsibility.
type settings struct {
	Prefix     string
	DataHome   string
	RuntimeDir string
	Executable string
	Proton     string
	UMU        string
}

// loadSettings resolves environment overrides and the build-time runtime defaults.
func loadSettings(defaultProton, defaultUMU string) (settings, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return settings{}, err
	}
	dataHome, err := applications.AbsolutePath(envOr("XDG_DATA_HOME", filepath.Join(home, ".local", "share")), home)
	if err != nil {
		return settings{}, err
	}
	dataHome, err = applications.CanonicalPath(dataHome)
	if err != nil {
		return settings{}, err
	}
	prefix, err := applications.AbsolutePath(envOr("WIN_RUN_WORKSPACE", filepath.Join(dataHome, "win-run", "prefixes", "default")), home)
	if err != nil {
		return settings{}, err
	}
	// The parent and its daemon need the same identity before a prefix exists.
	prefix, err = applications.CanonicalPath(prefix)
	if err != nil {
		return settings{}, err
	}
	runtimeDir := os.Getenv("XDG_RUNTIME_DIR")
	if runtimeDir == "" || !filepath.IsAbs(runtimeDir) {
		return settings{}, fmt.Errorf("XDG_RUNTIME_DIR must name an absolute session runtime directory")
	}
	executable, err := os.Executable()
	if err != nil {
		return settings{}, err
	}
	return settings{
		Prefix:     prefix,
		DataHome:   dataHome,
		RuntimeDir: filepath.Join(runtimeDir, "win-run"),
		Executable: executable,
		Proton:     envOr("WIN_RUN_PROTON", defaultProton),
		UMU:        envOr("WIN_RUN_UMU", defaultUMU),
	}, nil
}

func envOr(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}
