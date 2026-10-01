package applications

import (
	"errors"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestDesktopSyncOwnershipAndUnchanged(t *testing.T) {
	cfg := registryTestFixture(t)
	fixtureWrite(t, filepath.Join(cfg.Prefix, "drive_c", "Games", "Game.lnk"), "")
	fixtureCandidate(t, cfg.Prefix, "game.desktop", "Game", `C:\Games\Game.lnk`, "Name[ko]=게임\nComment=Play\n")
	if err := cfg.Sync(); err != nil {
		t.Fatal(err)
	}
	root := filepath.Join(cfg.DataHome, "applications")
	path := filepath.Join(root, "win-run-"+entryID(cfg.Prefix, `C:\Games\Game.lnk`)+".desktop")
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(data), "Name[ko]=win-run: 게임\n") {
		t.Fatalf("localization: %s", data)
	}
	before, _ := os.Stat(path)
	if err = cfg.Sync(); err != nil {
		t.Fatal(err)
	}
	after, _ := os.Stat(path)
	if !os.SameFile(before, after) || !before.ModTime().Equal(after.ModTime()) {
		t.Fatal("unchanged file replaced")
	}
	unrelated := filepath.Join(root, "win-run-other.desktop")
	fixtureWrite(t, unrelated, "[Desktop Entry]\nX-Win-Run-Managed=true\n")
	unmarked := filepath.Join(root, "win-run-wr1-000000000000000000000000.desktop")
	fixtureWrite(t, unmarked, "[Desktop Entry]\nName=Other\n")
	if err = os.Remove(filepath.Join(cfg.Prefix, "drive_c", "proton_shortcuts", "game.desktop")); err != nil {
		t.Fatal(err)
	}
	if err = cfg.Sync(); err != nil {
		t.Fatal(err)
	}
	if _, err = os.Stat(path); !os.IsNotExist(err) {
		t.Fatal("stale managed entry retained")
	}
	for _, p := range []string{unrelated, unmarked} {
		if _, err = os.Stat(p); err != nil {
			t.Fatal(err)
		}
	}
	fixtureCandidate(t, cfg.Prefix, "game.desktop", "Game", `C:\Games\Game.lnk`, "")
	fixtureWrite(t, path, "[Desktop Entry]\nName=Unrelated\n")
	if err = cfg.Sync(); err != nil {
		t.Fatal(err)
	}
	data, _ = os.ReadFile(path)
	if !strings.Contains(string(data), "Name=Unrelated") {
		t.Fatal("overwrote unrelated entry")
	}
}

func TestDesktopStartupWMClass(t *testing.T) {
	cfg := registryTestFixture(t)
	fixtureWrite(t, filepath.Join(cfg.Prefix, "drive_c", "Kakao.lnk"), "shortcut")
	fixtureCandidate(t, cfg.Prefix, "kakao.desktop", "KakaoTalk", `C:\Kakao.lnk`, "StartupWMClass=kakaotalk.exe\nIcon=kakaotalk\n")
	if err := cfg.Sync(); err != nil {
		t.Fatal(err)
	}
	outputPath := filepath.Join(cfg.DataHome, "applications", "win-run-"+entryID(cfg.Prefix, `C:\Kakao.lnk`)+".desktop")
	values, err := readDesktopEntry(outputPath)
	if err != nil {
		t.Fatal(err)
	}
	if values["StartupWMClass"] != "kakaotalk.exe" || values["Icon"] != "kakaotalk" {
		t.Fatalf("generated values: %v", values)
	}
	if values["Categories"] != "Utility;" {
		t.Fatalf("generated Categories: %q", values["Categories"])
	}
	contents := desktopRender(cfg, entry{StartupWMClass: "quote\"slash\\\nclass"})
	fixtureWrite(t, outputPath, string(contents))
	values, err = readDesktopEntry(outputPath)
	if err != nil {
		t.Fatal(err)
	}
	decoded, err := decodeDesktopValue(values["StartupWMClass"])
	if err != nil || decoded != "quote\"slash\\\nclass" {
		t.Fatalf("WMClass round trip %q: %v", decoded, err)
	}
}

func TestDesktopStatPermissionPreservesManagedEntry(t *testing.T) {
	cfg := registryTestFixture(t)
	shortcut := `C:\Games\Game.lnk`
	target := filepath.Join(cfg.Prefix, "drive_c", "Games", "Game.lnk")
	fixtureWrite(t, target, "shortcut")
	fixtureCandidate(t, cfg.Prefix, "game.desktop", "Game", shortcut, "")
	if err := cfg.Sync(); err != nil {
		t.Fatal(err)
	}
	outputPath := filepath.Join(cfg.DataHome, "applications", "win-run-"+entryID(cfg.Prefix, shortcut)+".desktop")
	original, err := os.ReadFile(outputPath)
	if err != nil {
		t.Fatal(err)
	}
	directory := filepath.Dir(target)
	// readDesktopEntry permission allows casing resolution; missing search permission causes
	// Stat of the shortcut to fail instead of treating it as a missing entry.
	if err := os.Chmod(directory, 0400); err != nil {
		t.Fatal(err)
	}
	defer os.Chmod(directory, 0755)
	if _, err := os.Stat(target); err == nil {
		t.Skip("current user bypasses directory search permissions")
	}
	if err := cfg.Sync(); !errors.Is(err, fs.ErrPermission) {
		t.Fatalf("sync error: %v", err)
	}
	current, err := os.ReadFile(outputPath)
	if err != nil || string(current) != string(original) {
		t.Fatalf("managed entry changed on permission error: %v", err)
	}
}

func TestDesktopSharedDataHomePrefixes(t *testing.T) {
	first := registryTestFixture(t)
	second := registryTestFixture(t)
	second.DataHome = first.DataHome
	second.Prefix = filepath.Join(filepath.Dir(second.Prefix), "prefix space%")
	shortcut := `C:\Games\Game.lnk`
	for _, cfg := range []Registry{first, second} {
		fixtureWrite(t, filepath.Join(cfg.Prefix, "drive_c", "Games", "Game.lnk"), "shortcut")
		fixtureCandidate(t, cfg.Prefix, "game.desktop", "Game", shortcut, "")
		if err := cfg.Sync(); err != nil {
			t.Fatal(err)
		}
	}
	firstID := entryID(first.Prefix, shortcut)
	secondID := entryID(second.Prefix, shortcut)
	if firstID == secondID {
		t.Fatal("identical shortcut IDs across prefixes")
	}
	outputPath := func(id string) string {
		return filepath.Join(first.DataHome, "applications", "win-run-"+id+".desktop")
	}
	for _, cfg := range []Registry{first, second} {
		values, err := readDesktopEntry(outputPath(entryID(cfg.Prefix, shortcut)))
		if err != nil {
			t.Fatal(err)
		}
		prefix, err := decodeDesktopValue(values["X-Win-Run-Prefix"])
		if err != nil || prefix != cfg.Prefix {
			t.Fatalf("prefix marker %q: %v", prefix, err)
		}
		expectedExec := execArgument(cfg.Executable) + " launch " + entryID(cfg.Prefix, shortcut) + " --prefix " + execArgument(cfg.Prefix)
		if values["Exec"] != expectedExec {
			t.Fatalf("Exec: got %q, want %q", values["Exec"], expectedExec)
		}
	}
	// Even a strict filename and managed marker do not authorize modifying a
	// file carrying another prefix, or an older file with no prefix marker.
	collisionPath := outputPath(firstID)
	foreignContents, err := os.ReadFile(outputPath(secondID))
	if err != nil {
		t.Fatal(err)
	}
	fixtureWrite(t, collisionPath, string(foreignContents))
	if err := first.Sync(); err != nil {
		t.Fatal(err)
	}
	collisionContents, err := os.ReadFile(collisionPath)
	if err != nil || string(collisionContents) != string(foreignContents) {
		t.Fatal("overwrote another prefix's entry")
	}
	// Restore a valid first entry so cleanup can be checked independently.
	if err := os.Remove(collisionPath); err != nil {
		t.Fatal(err)
	}
	if err := first.Sync(); err != nil {
		t.Fatal(err)
	}
	unscoped := filepath.Join(first.DataHome, "applications", "win-run-wr1-000000000000000000000000.desktop")
	fixtureWrite(t, unscoped, "[Desktop Entry]\nX-Win-Run-Managed=true\nName=Unscoped\n")
	if err := os.Remove(filepath.Join(first.Prefix, "drive_c", "proton_shortcuts", "game.desktop")); err != nil {
		t.Fatal(err)
	}
	if err := first.Sync(); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(outputPath(firstID)); !os.IsNotExist(err) {
		t.Fatalf("first prefix stale entry: %v", err)
	}
	for _, path := range []string{outputPath(secondID), unscoped} {
		if _, err := os.Stat(path); err != nil {
			t.Fatalf("removed unrelated prefix entry %s: %v", path, err)
		}
	}
}

func registryTestFixture(t testing.TB) Registry {
	t.Helper()
	root := t.TempDir()
	return Registry{Prefix: filepath.Join(root, "prefix"), DataHome: filepath.Join(root, "data"), Executable: filepath.Join(root, "bin", "win-run")}
}
