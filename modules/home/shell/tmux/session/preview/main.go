package preview

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"unicode"

	"github.com/charmbracelet/x/ansi"
)

const (
	reset  = "\x1b[0m"
	dim    = "\x1b[2m"
	accent = "\x1b[1;36m"
	label  = "\x1b[1;34m"
)

type window struct {
	index   string
	active  bool
	name    string
	pane    string
	cursorX int
	lines   []string
}

func tmux(args ...string) (string, error) {
	command := []string{}
	if socket := os.Getenv("TMS_SOCKET"); socket != "" {
		command = append(command, "-S", socket)
	}
	command = append(command, args...)
	output, err := exec.Command("tmux", command...).Output()
	return string(output), err
}

func cleanLabel(value string) string {
	return strings.Map(func(r rune) rune {
		if unicode.IsPrint(r) {
			return r
		}
		return ' '
	}, value)
}

func fit(value string, start, width int) string {
	if width <= 0 {
		return ""
	}
	clipped := ansi.Cut(value, start, start+width)
	return clipped + reset + strings.Repeat(" ", max(0, width-ansi.StringWidth(clipped)))
}

func previewSize(name string, fallback int) int {
	value, err := strconv.Atoi(os.Getenv(name))
	if err != nil || value < 1 {
		return fallback
	}
	return value
}

func capture(w *window, lines int) {
	output, err := tmux("capture-pane", "-p", "-e", "-t", w.pane)
	if err != nil {
		w.lines = []string{"Pane no longer exists."}
		return
	}
	w.lines = strings.Split(strings.TrimSuffix(output, "\n"), "\n")
	for len(w.lines) > 0 && strings.TrimSpace(ansi.Strip(w.lines[len(w.lines)-1])) == "" {
		w.lines = w.lines[:len(w.lines)-1]
	}
	if len(w.lines) > lines {
		w.lines = w.lines[len(w.lines)-lines:]
	}
}

func render(target string, out *bufio.Writer) {
	session, err := tmux("display-message", "-p", "-t", target, "#{session_name}")
	if err != nil {
		fmt.Fprintln(out, "This item no longer exists. Press Enter to refresh and choose again.")
		return
	}
	listing, err := tmux("list-windows", "-t", target, "-F", "#{window_index}\x1f#{window_active}\x1f#{window_name}\x1f#{pane_id}\x1f#{cursor_x}")
	if err != nil {
		fmt.Fprintln(out, "This item no longer exists. Press Enter to refresh and choose again.")
		return
	}

	var windows []window
	for _, line := range strings.Split(strings.TrimSuffix(listing, "\n"), "\n") {
		parts := strings.Split(line, "\x1f")
		if len(parts) != 5 {
			continue
		}
		cursorX, _ := strconv.Atoi(parts[4])
		windows = append(windows, window{
			index: parts[0], active: parts[1] == "1", name: cleanLabel(parts[2]),
			pane: parts[3], cursorX: cursorX,
		})
	}
	if len(windows) == 0 {
		fmt.Fprintln(out, "This session has no windows.")
		return
	}

	columns := max(20, previewSize("FZF_PREVIEW_COLUMNS", 80))
	height := max(4, previewSize("FZF_PREVIEW_LINES", 30))
	perRow := min(len(windows), max(1, (columns+1)/24))
	rowCount := (len(windows) + perRow - 1) / perRow
	rowHeight := max(3, (height-1-rowCount)/rowCount)
	countLabel := "windows"
	if len(windows) == 1 {
		countLabel = "window"
	}
	fmt.Fprintln(out, fit(fmt.Sprintf(" %s  ·  %d %s", cleanLabel(strings.TrimSpace(session)), len(windows), countLabel), 0, columns))
	fmt.Fprintln(out, dim+strings.Repeat("─", columns)+reset)

	separator := dim + "│" + reset
	for rowStart := 0; rowStart < len(windows); rowStart += perRow {
		if rowStart > 0 {
			fmt.Fprintln(out, dim+strings.Repeat("─", columns)+reset)
		}
		row := windows[rowStart:min(rowStart+perRow, len(windows))]
		usable := columns - len(row) + 1
		widths := make([]int, len(row))
		labels := make([]string, len(row))
		for i := range row {
			widths[i] = usable / len(row)
			if i < usable%len(row) {
				widths[i]++
			}
			marker, style := " ", label
			if row[i].active {
				marker, style = "●", accent
			}
			title := fmt.Sprintf(" %s %s:%s ", marker, row[i].index, row[i].name)
			labels[i] = style + fit(title, 0, widths[i])
			capture(&row[i], rowHeight-1)
		}
		fmt.Fprintln(out, strings.Join(labels, separator))
		for line := 0; line < rowHeight-1; line++ {
			cells := make([]string, len(row))
			for i := range row {
				content := ""
				if line < len(row[i].lines) {
					content = row[i].lines[line]
				}
				offset := max(0, row[i].cursorX-widths[i]/2)
				cells[i] = fit(content, offset, widths[i])
			}
			fmt.Fprintln(out, strings.Join(cells, separator))
		}
	}
}

func Render(target string, output io.Writer) {
	buffered := bufio.NewWriter(output)
	render(target, buffered)
	_ = buffered.Flush()
}
