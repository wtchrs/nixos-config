package preview

import (
	"strings"
	"testing"

	"github.com/charmbracelet/x/ansi"
)

func TestFitKeepsTerminalCellWidth(t *testing.T) {
	line := "\x1b[31m가😀a\x1b[0m"
	for _, test := range []struct {
		start, width int
		want         string
	}{
		{0, 4, "가😀"},
		{2, 3, "😀a"},
		{0, 6, "가😀a "},
	} {
		got := fit(line, test.start, test.width)
		if ansi.StringWidth(got) != test.width || ansi.Strip(got) != test.want {
			t.Errorf("fit(%q, %d, %d) = %q, width %d; want %q, width %d",
				line, test.start, test.width, ansi.Strip(got), ansi.StringWidth(got), test.want, test.width)
		}
		if strings.Contains(got, "\x1b[31m") && !strings.Contains(got, reset) {
			t.Errorf("fit(%q, %d, %d) leaked color", line, test.start, test.width)
		}
	}
}
