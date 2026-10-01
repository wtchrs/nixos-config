package applications

import (
	"path/filepath"
	"testing"
)

// configuration keeps CLI fixture fields together without widening WatcherOptions.
type configuration struct {
	Prefix     string
	DataHome   string
	RuntimeDir string
	Executable string
	Proton     string
	UMU        string
}

func (cfg configuration) options() WatcherOptions {
	return WatcherOptions{
		Prefix:     cfg.Prefix,
		DataHome:   cfg.DataHome,
		RuntimeDir: cfg.RuntimeDir,
		Executable: cfg.Executable,
	}
}

func (e *integrationEnv) options() WatcherOptions { return e.cfg.options() }

func catalogTestConfig(t *testing.T) configuration {
	t.Helper()
	root := t.TempDir()
	return configuration{
		Prefix:     filepath.Join(root, "prefix"),
		DataHome:   filepath.Join(root, "data"),
		Executable: filepath.Join(root, "bin", "win-run"),
	}
}

func catalogTestWrite(t *testing.T, path, content string) {
	t.Helper()
	fixtureWrite(t, path, content)
}

func catalogTestCandidate(t *testing.T, cfg configuration, file, name, shortcut, extra string) {
	t.Helper()
	fixtureCandidate(t, cfg.Prefix, file, name, shortcut, extra)
}
