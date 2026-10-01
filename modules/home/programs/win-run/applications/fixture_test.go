package applications

import (
	"os"
	"path/filepath"
	"testing"
)

// fixturePrefix returns a unique prefix path in a temporary directory.
func fixturePrefix(t testing.TB) string {
	t.Helper()
	return filepath.Join(t.TempDir(), "prefix")
}

// fixtureWrite creates parent directories and writes a fixture file.
func fixtureWrite(t testing.TB, path, content string) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(path), 0755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte(content), 0644); err != nil {
		t.Fatal(err)
	}
}

// fixtureCandidate writes a DW-Proton desktop candidate for a shortcut.
func fixtureCandidate(t testing.TB, prefix, file, name, shortcut, extra string) {
	t.Helper()
	fixtureWrite(t, filepath.Join(prefix, "drive_c", "proton_shortcuts", file), "[Desktop Entry]\nType=Application\nName="+escapeDesktopValue(name)+"\nExec="+escapeDesktopValue(`"`+shortcut+`"`)+"\n"+extra)
}
