package applications

import (
	"errors"
	"image"
	"image/png"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestCatalogDiscovery(t *testing.T) {
	prefix := fixturePrefix(t)
	target := filepath.Join(prefix, "drive_c", "Games", "My Game.LNK")
	fixtureWrite(t, target, "shortcut")
	fixtureCandidate(t, prefix, "game.desktop", "My Game", `C:\games\my game.lnk`, "Name[ko]=게임\nComment=Play\\sme\n")
	fixtureCandidate(t, prefix, "duplicate.desktop", "My Game", `c:/GAMES/My Game.LNK`, "")
	fixtureCandidate(t, prefix, "hidden.desktop", "Hidden", `C:\games\my game.lnk`, "Hidden=true\n")
	fixtureCandidate(t, prefix, "remove.desktop", "Remove Game", `C:\games\my game.lnk`, "")
	fixtureCandidate(t, prefix, "missing.desktop", "Missing", `C:\games\missing.lnk`, "")
	fixtureCandidate(t, prefix, "nested/ignored.desktop", "Nested", `C:\games\nested.lnk`, "")
	entries, err := Scan(prefix)
	if err != nil {
		t.Fatal(err)
	}
	if len(entries) != 1 {
		t.Fatalf("entries: %+v", entries)
	}
	if entries[0].ShortcutPath != target {
		t.Fatalf("resolved %q", entries[0].ShortcutPath)
	}
	if entryID(prefix, `C:\games\my game.lnk`) != entryID(prefix, `c:/GAMES/My Game.LNK`) {
		t.Fatal("unstable identity")
	}
}
func TestCatalogExec(t *testing.T) {
	for _, raw := range []string{escapeDesktopValue(`"C:\Games\A.lnk"`), escapeDesktopValue(`C:\Games\A.lnk`)} {
		got, err := catalogShortcut(raw)
		if err != nil || got != `C:\Games\A.lnk` {
			t.Fatalf("%q: %q %v", raw, got, err)
		}
	}
	for _, raw := range []string{`"C:\\a.lnk" extra`, `"C:\\a.lnk`, `C:\\a.exe`, `C:\\a.lnk %f`, `"C:\\%f.lnk"`} {
		if _, err := catalogShortcut(raw); err == nil {
			t.Fatalf("accepted %q", raw)
		}
	}
}
func TestCatalogWatchMissingAndFiltered(t *testing.T) {
	prefix := fixturePrefix(t)
	fixtureWrite(t, filepath.Join(prefix, "drive_c", "Games", "existing"), "")
	fixtureCandidate(t, prefix, "missing.desktop", "Remove", `C:\games\Absent\new.lnk`, "Hidden=true\n")
	fixtureCandidate(t, prefix, "unmapped.desktop", "Unmapped", `E:\Apps\new.lnk`, "")
	icons := filepath.Join(catalogRoot(prefix), "icons", "nested")
	if err := os.MkdirAll(icons, 0755); err != nil {
		t.Fatal(err)
	}
	paths, err := watchPaths(prefix)
	if err != nil {
		t.Fatal(err)
	}
	joined := strings.Join(paths, "\n")
	for _, want := range []string{filepath.Join(prefix, "drive_c", "Games", "Absent"), filepath.Join(prefix, "dosdevices", "e:", "Apps"), icons, catalogRoot(prefix)} {
		if !strings.Contains(joined, want) {
			t.Fatalf("missing %s in %v", want, paths)
		}
	}
}
func TestCatalogDriveAndIcons(t *testing.T) {
	prefix := fixturePrefix(t)
	drive := filepath.Join(t.TempDir(), "mapped")
	fixtureWrite(t, filepath.Join(drive, "App", "Go.lnk"), "")
	if err := os.MkdirAll(filepath.Join(prefix, "dosdevices"), 0755); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(drive, filepath.Join(prefix, "dosdevices", "d:")); err != nil {
		t.Fatal(err)
	}
	got, err := catalogResolve(prefix, `D:\app\go.lnk`)
	if err != nil || got != filepath.Join(prefix, "dosdevices", "d:", "App", "Go.lnk") {
		t.Fatalf("%s %v", got, err)
	}
	var largest string
	for _, size := range []int{16, 64} {
		path := filepath.Join(catalogRoot(prefix), "icons", strings.Repeat("x", size), "game.png")
		if err := os.MkdirAll(filepath.Dir(path), 0755); err != nil {
			t.Fatal(err)
		}
		f, err := os.Create(path)
		if err != nil {
			t.Fatal(err)
		}
		if err = png.Encode(f, image.NewRGBA(image.Rect(0, 0, size, size))); err != nil {
			t.Fatal(err)
		}
		f.Close()
		largest = path
	}
	if got := catalogIcon(prefix, "game"); got != largest {
		t.Fatalf("icon %s", got)
	}
}

func TestCatalogDWProtonExec(t *testing.T) {
	// Literal desktop-file text: four backslashes become one Windows separator
	// after desktop string decoding and quoted Exec argument decoding.
	raw := `"C:\\\\ProgramData\\\\Microsoft\\\\Windows\\\\Start Menu\\\\Programs\\\\KakaoTalk\\\\KakaoTalk.lnk"`
	want := `C:\ProgramData\Microsoft\Windows\Start Menu\Programs\KakaoTalk\KakaoTalk.lnk`
	shortcut, err := catalogShortcut(raw)
	if err != nil || shortcut != want {
		t.Fatalf("DW-Proton Exec: got %q, error %v", shortcut, err)
	}
	prefix := fixturePrefix(t)
	target := filepath.Join(prefix, "drive_c", "ProgramData", "Microsoft", "Windows", "Start Menu", "Programs", "KakaoTalk", "KakaoTalk.lnk")
	fixtureWrite(t, target, "shortcut")
	fixtureWrite(t, filepath.Join(catalogRoot(prefix), "kakao.desktop"), "[Desktop Entry]\nName=KakaoTalk\nExec="+raw+"\nStartupWMClass=kakaotalk.exe\n")
	entries, err := Scan(prefix)
	if err != nil || len(entries) != 1 {
		t.Fatalf("entries: %+v, error %v", entries, err)
	}
	if entries[0].ShortcutPath != target || entries[0].StartupWMClass != "kakaotalk.exe" {
		t.Fatalf("KakaoTalk entry: %+v", entries[0])
	}
}

func TestCatalogDisappearingCandidate(t *testing.T) {
	prefix := fixturePrefix(t)
	candidate := filepath.Join(catalogRoot(prefix), "gone.desktop")
	fixtureWrite(t, candidate, "[Desktop Entry]\nName=Gone\n")
	listed, err := catalogCandidates(prefix)
	if err != nil || len(listed) != 1 {
		t.Fatalf("listed %v: %v", listed, err)
	}
	if err := os.Remove(candidate); err != nil {
		t.Fatal(err)
	}
	values, err := catalogReadCandidate(listed[0])
	if err != nil || values != nil {
		t.Fatalf("disappeared candidate: %v, %v", values, err)
	}
	// A dangling candidate exercises the same ENOENT at open in both scans.
	if err := os.Symlink(filepath.Join(t.TempDir(), "absent"), candidate); err != nil {
		t.Fatal(err)
	}
	if entries, err := Scan(prefix); err != nil || len(entries) != 0 {
		t.Fatalf("discover dangling candidate: %v, %v", entries, err)
	}
	if _, err := watchPaths(prefix); err != nil {
		t.Fatal(err)
	}
}

func TestCatalogUnreadableCandidate(t *testing.T) {
	prefix := fixturePrefix(t)
	candidate := filepath.Join(catalogRoot(prefix), "unreadable.desktop")
	fixtureWrite(t, candidate, "[Desktop Entry]\nName=Unreadable\n")
	if err := os.Chmod(candidate, 0); err != nil {
		t.Fatal(err)
	}
	defer os.Chmod(candidate, 0644)
	if _, err := os.ReadFile(candidate); err == nil {
		t.Skip("current user can read permission-restricted files")
	}
	if _, err := Scan(prefix); !errors.Is(err, fs.ErrPermission) {
		t.Fatalf("discover error: %v", err)
	}
	if _, err := watchPaths(prefix); !errors.Is(err, fs.ErrPermission) {
		t.Fatalf("watch error: %v", err)
	}
}

func TestCatalogThemeIconFallback(t *testing.T) {
	prefix := fixturePrefix(t)
	for _, name := range []string{"kakaotalk", "application-x-executable", "org.example.App"} {
		if got := catalogIcon(prefix, name); got != name {
			t.Fatalf("theme fallback %q: %q", name, got)
		}
	}
	for _, name := range []string{"../missing", "bad name", "/absent/icon.png"} {
		if got := catalogIcon(prefix, name); got != "" {
			t.Fatalf("invalid fallback %q: %q", name, got)
		}
	}
}

func TestCatalogKoreanUninstallNames(t *testing.T) {
	for _, name := range []string{"카카오톡 제거", "카카오톡 삭제", "카카오톡 (언인스톨)", "제거", "삭제 - 카카오톡"} {
		if !catalogIsUninstall(name) {
			t.Errorf("uninstall name accepted: %q", name)
		}
	}
	for _, name := range []string{"카카오톡", "삭제복구 도구", "제거제", "언인스톨러 연구", "앱삭제", "삭제_tool"} {
		if catalogIsUninstall(name) {
			t.Errorf("unrelated name filtered: %q", name)
		}
	}
	prefix := fixturePrefix(t)
	fixtureWrite(t, filepath.Join(prefix, "drive_c", "Kakao.lnk"), "shortcut")
	fixtureCandidate(t, prefix, "remove.desktop", "KakaoTalk", `C:\Kakao.lnk`, "Name[ko]=카카오톡 제거\n")
	entries, err := Scan(prefix)
	if err != nil || len(entries) != 0 {
		t.Fatalf("localized uninstall entries: %+v, error %v", entries, err)
	}
}
