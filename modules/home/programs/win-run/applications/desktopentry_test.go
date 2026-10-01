package applications

import (
	"errors"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
)

func TestDesktopExecEscaping(t *testing.T) {
	original := "/tmp/a space/quote\"back\\tick`dollar$percent%/win-run"
	if got, err := parseExecArgument(execArgument(original)); err != nil || got != original {
		t.Fatalf("round trip %q %v", got, err)
	}
	encoded := execArgument(original)
	decoded, err := decodeDesktopValue(encoded)
	if err != nil {
		t.Fatal(err)
	}
	// Exercise both escape layers with a Windows payload as well.
	shortcut := `C:\space dir\quote"back\tick` + "`" + `dollar$percent%.lnk`
	got, err := parseExecArgument(execArgument(shortcut))
	if err != nil || got != shortcut {
		t.Fatalf("round trip %q %v", got, err)
	}
	if !strings.Contains(decoded, "%%") || !strings.HasPrefix(decoded, `"`) || !strings.Contains(decoded, `\$`) {
		t.Fatalf("Exec encoding %q", decoded)
	}
}

func TestParseArgument(t *testing.T) {
	for _, value := range []string{"", "plain", "/tmp/tool.exe", "한글 space", "line\nreturn\rtab\t", `quote"slash\percent%tick` + "`$"} {
		got, err := parseExecArgument(execArgument(value))
		if err != nil || got != value {
			t.Errorf("round trip %q: %q, %v", value, got, err)
		}
	}
	for _, raw := range []string{`"unclosed`, `"one" two`, `one two`, `%f`, `"%U"`, `trailing\`, `bad\q`, `unquoted$`} {
		if _, err := parseExecArgument(raw); err == nil {
			t.Errorf("accepted %q", raw)
		}
	}
}

func TestDecodeAndEscape(t *testing.T) {
	value := "한글 \\ \"\n\r\t"
	if got, err := decodeDesktopValue(escapeDesktopValue(value)); err != nil || got != value {
		t.Fatalf("round trip %q: %v", got, err)
	}
	if got, err := decodeDesktopValue(`a\sb\"c`); err != nil || got != `a b"c` {
		t.Fatalf("desktop escapes %q: %v", got, err)
	}
	for _, raw := range []string{`trailing\`, `bad\q`} {
		if _, err := decodeDesktopValue(raw); err == nil {
			t.Errorf("accepted %q", raw)
		}
	}
}

func TestReadDesktopSection(t *testing.T) {
	path := filepath.Join(t.TempDir(), "entry.desktop")
	contents := "Name=ignored\n\ufeff[Desktop Entry]\n# Comment=ignored\n Name = First \nName=Last\nName[ko]=게임\nComment=Play\\sme\n[Other]\nName=ignored\n"
	if err := os.WriteFile(path, []byte(contents), 0644); err != nil {
		t.Fatal(err)
	}
	values, err := readDesktopEntry(path)
	if err != nil {
		t.Fatal(err)
	}
	want := map[string]string{"Name": "Last", "Name[ko]": "게임", "Comment": `Play\sme`}
	if !reflect.DeepEqual(values, want) {
		t.Fatalf("values: %v", values)
	}
	if _, err := readDesktopEntry(path + ".missing"); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("missing file: %v", err)
	}
	if err := os.WriteFile(path, []byte("[Desktop Entry]\nName="+strings.Repeat("x", 1024*1024)), 0644); err != nil {
		t.Fatal(err)
	}
	if _, err := readDesktopEntry(path); err == nil {
		t.Fatal("scanner error not returned")
	}
}
