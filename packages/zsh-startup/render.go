package main

import (
	"fmt"
	"math"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"charm.land/lipgloss/v2"
	"github.com/charmbracelet/colorprofile"
	"github.com/charmbracelet/x/ansi"
	"github.com/charmbracelet/x/term"
)

const (
	maxWidth     = 110 // keep lines readable on wide terminals
	pipeWidth    = 100 // width when stdout is not a terminal
	indent       = "  "
	columnGap    = "  "
	barWidth     = 18
	topRows      = 8
	topCallTrees = 8
	minFlexWidth = 12
)

// Styles. Every color comes from theme in theme.go.
var (
	headingStyle  = lipgloss.NewStyle().Foreground(theme.Heading).Bold(true)
	sectionStyle  = lipgloss.NewStyle().Foreground(theme.Accent).Bold(true)
	emphasisStyle = lipgloss.NewStyle().Foreground(theme.Emphasis).Bold(true)
	textStyle     = lipgloss.NewStyle().Foreground(theme.Text)
	labelStyle    = lipgloss.NewStyle().Foreground(theme.Label).Bold(true)
	mutedStyle    = lipgloss.NewStyle().Foreground(theme.Muted)
	betterStyle   = lipgloss.NewStyle().Foreground(theme.Better).Bold(true)
	worseStyle    = lipgloss.NewStyle().Foreground(theme.Worse).Bold(true)
	addedStyle    = lipgloss.NewStyle().Foreground(theme.Added)
	removedStyle  = lipgloss.NewStyle().Foreground(theme.Removed)
	warningStyle  = lipgloss.NewStyle().Foreground(theme.Warning)
	barStyle      = lipgloss.NewStyle().Foreground(theme.Bar).Background(theme.BarTrack)
	trackStyle    = lipgloss.NewStyle().Foreground(theme.BarTrack)
	boxStyle      = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(theme.Accent).
			Padding(0, 1)
)

// renderer lays out the output. In plain mode, when stdout is not a terminal,
// it drops the header box and draws bars with ASCII characters; the writer
// in main.go strips the colors. noColor is set when the writer strips the
// colors on a terminal too, for example because NO_COLOR is set.
type renderer struct {
	plain   bool
	noColor bool
	width   int
}

func newRenderer(profile colorprofile.Profile) renderer {
	plain := profile <= colorprofile.NoTTY
	noColor := profile <= colorprofile.ASCII

	width := pipeWidth
	if !plain {
		columns, _, err := term.GetSize(os.Stdout.Fd())
		if err == nil && columns > 0 {
			width = columns
		}
	}
	return renderer{plain: plain, noColor: noColor, width: min(width, maxWidth)}
}

// contentWidth is the width inside a section, after the indent.
func (r renderer) contentWidth() int {
	return r.width - len(indent)
}

func (r renderer) header(title string, lines ...string) string {
	// The box adds a border and one column of padding on each side.
	available := r.width
	if !r.plain {
		available -= 4
	}

	all := []string{headingStyle.Render(title)}
	for _, line := range lines {
		all = append(all, r.fit(line, available))
	}

	body := strings.Join(all, "\n")
	if r.plain {
		return body + "\n"
	}
	return boxStyle.Render(body) + "\n"
}

// fit cuts a line that is wider than width.
func (r renderer) fit(line string, width int) string {
	if lipgloss.Width(line) <= width {
		return line
	}
	return cut(line, width, false)
}

// wrap breaks text into lines no wider than the full output width. lipgloss
// pads wrapped lines to the width, so the padding is trimmed again.
func (r renderer) wrap(style lipgloss.Style, text string) string {
	var lines []string
	for line := range strings.SplitSeq(style.Width(r.width).Render(text), "\n") {
		lines = append(lines, strings.TrimRight(line, " "))
	}
	return strings.Join(lines, "\n")
}

func (r renderer) section(title, note, body string) string {
	marker := sectionStyle.Render("▍ " + title)
	if r.plain {
		marker = "## " + title
	}
	if note != "" {
		styledNote := mutedStyle.Render(note)
		// A note that does not fit beside the title moves to its own line,
		// because cutting it would drop the numbers at its end.
		if lipgloss.Width(marker)+2+lipgloss.Width(styledNote) <= r.width {
			marker += "  " + styledNote
		} else {
			marker += "\n" + indent + r.fit(styledNote, r.contentWidth())
		}
	}

	var lines []string
	for line := range strings.SplitSeq(body, "\n") {
		if line == "" {
			lines = append(lines, "")
		} else {
			lines = append(lines, indent+line)
		}
	}
	return "\n" + marker + "\n" + strings.Join(lines, "\n") + "\n"
}

// joinDot joins parts with a muted middle dot.
func joinDot(parts ...string) string {
	return strings.Join(parts, mutedStyle.Render(" · "))
}

type column struct {
	header string
	right  bool
	// flex columns share the width that the other columns leave. Their cells
	// are cut to fit, from the left when cutLeft is set (for paths).
	flex    bool
	cutLeft bool
}

func (r renderer) table(columns []column, rows [][]string) string {
	widths := make([]int, len(columns))
	for i, column := range columns {
		widths[i] = lipgloss.Width(column.header)
	}
	for _, row := range rows {
		for i, cell := range row {
			widths[i] = max(widths[i], lipgloss.Width(cell))
		}
	}

	r.fitFlexColumns(columns, widths)

	rule := "─"
	if r.plain {
		rule = "-"
	}

	var lines []string
	headers := make([]string, len(columns))
	for i, column := range columns {
		headers[i] = labelStyle.Render(column.header)
	}
	lines = append(lines, r.tableRow(columns, widths, headers))
	lines = append(lines, mutedStyle.Render(strings.Repeat(rule, sum(widths)+len(columnGap)*(len(columns)-1))))
	for _, row := range rows {
		lines = append(lines, r.tableRow(columns, widths, row))
	}
	return strings.Join(lines, "\n")
}

// fitFlexColumns shrinks the flex columns so that the table fits the width.
// A flex column that is narrower than an equal share keeps its width, and the
// wider flex columns split the width that it leaves.
func (r renderer) fitFlexColumns(columns []column, widths []int) {
	available := r.contentWidth() - len(columnGap)*(len(columns)-1)
	var wide []int
	for i, column := range columns {
		if column.flex {
			wide = append(wide, i)
		} else {
			available -= widths[i]
		}
	}

	// Each pass settles the columns that fit an equal share. The share grows
	// in the next pass, so a settled column stays settled.
	for len(wide) > 0 {
		share := available / len(wide)
		var wider []int
		for _, i := range wide {
			if widths[i] <= share {
				available -= widths[i]
			} else {
				wider = append(wider, i)
			}
		}

		if len(wider) == len(wide) {
			for _, i := range wider {
				widths[i] = min(widths[i], max(minFlexWidth, share))
			}
			return
		}
		wide = wider
	}
}

func (r renderer) tableRow(columns []column, widths []int, cells []string) string {
	parts := make([]string, len(columns))
	for i, column := range columns {
		cell := cells[i]
		if lipgloss.Width(cell) > widths[i] {
			cell = cut(cell, widths[i], column.cutLeft)
		}

		padding := strings.Repeat(" ", widths[i]-lipgloss.Width(cell))
		if column.right {
			parts[i] = padding + cell
		} else {
			parts[i] = cell + padding
		}
	}
	return strings.TrimRight(strings.Join(parts, columnGap), " ")
}

// cut shortens text to width cells and marks the cut with an ellipsis.
func cut(text string, width int, fromLeft bool) string {
	if fromLeft {
		return ansi.TruncateLeft(text, lipgloss.Width(text)-width+1, "…")
	}
	return ansi.Truncate(text, width, "…")
}

func sum(values []int) int {
	total := 0
	for _, value := range values {
		total += value
	}
	return total
}

// bar draws share (0 to 1) as a bar with eighth-block precision, followed by
// the percentage.
func (r renderer) bar(share float64) string {
	share = math.Max(0, math.Min(1, share))
	label := " " + textStyle.Render(formatShare(share))

	if r.plain {
		filled := int(math.Round(share * barWidth))
		return strings.Repeat("#", filled) + strings.Repeat(".", barWidth-filled) + label
	}

	eighths := int(math.Round(share * barWidth * 8))
	full := eighths / 8
	partial := eighths % 8

	var builder strings.Builder
	builder.WriteString(barStyle.Render(strings.Repeat("█", full)))
	rest := barWidth - full
	if partial > 0 {
		partialBlocks := []string{"", "▏", "▎", "▍", "▌", "▋", "▊", "▉"}
		builder.WriteString(barStyle.Render(partialBlocks[partial]))
		rest--
	}
	// The track has the same glyph as the filled part and differs only in
	// color, so without colors it needs a glyph of its own.
	track := "█"
	if r.noColor {
		track = "░"
	}
	builder.WriteString(trackStyle.Render(strings.Repeat(track, rest)))
	return builder.String() + label
}

func formatShare(share float64) string {
	percent := share * 100
	if percent > 0 && percent < 1 {
		return "<1%"
	}
	return fmt.Sprintf("%.0f%%", percent)
}

// formatNumber shows two decimals for small values, where they still matter.
func formatNumber(value float64) string {
	if math.Abs(value) < 10 {
		return fmt.Sprintf("%.2f", value)
	}
	return fmt.Sprintf("%.1f", value)
}

func formatMs(value float64) string {
	return formatNumber(value) + " ms"
}

// formatChange colors a time difference: faster is better.
func formatChange(diff float64) string {
	return colorChange(diff, formatMs(math.Abs(diff)))
}

// formatChangeNumber is formatChange without the unit, for table columns
// whose header names the unit.
func formatChangeNumber(diff float64) string {
	return colorChange(diff, formatNumber(math.Abs(diff)))
}

func colorChange(diff float64, magnitude string) string {
	switch {
	case diff < 0:
		return betterStyle.Render("−" + magnitude)
	case diff > 0:
		return worseStyle.Render("+" + magnitude)
	default:
		return mutedStyle.Render("0")
	}
}

var (
	storePath     = regexp.MustCompile(`^/nix/store/[0-9a-z]{32}-([^/]+)(/.*)?$`)
	zshFunction   = regexp.MustCompile(`/share/zsh/[^/]+/functions/([^/]+)$`)
	storeProgram  = regexp.MustCompile(`/nix/store/[0-9a-z]{32}-[^/\s]+/bin/`)
	storeHashPart = regexp.MustCompile(`/nix/store/[0-9a-z]{32}-`)
	anonFunction  = regexp.MustCompile(`^\(anon\) \[(.+):(\d+)\]$`)
)

// shortPath drops the Nix store hash and shortens the home directory to ~.
// It keeps the package name and the file name, which identify the source.
// Autoloaded zsh functions become zsh/functions/<name>.
func shortPath(path string) string {
	if match := zshFunction.FindStringSubmatch(path); match != nil {
		return "zsh/functions/" + match[1]
	}

	if match := storePath.FindStringSubmatch(path); match != nil {
		name := match[1]
		rest := match[2]
		if rest == "" {
			return name
		}
		if strings.Count(rest, "/") == 1 {
			return name + rest
		}
		return name + "/…/" + filepath.Base(rest)
	}

	home, err := os.UserHomeDir()
	if err == nil && home != "" {
		if path == home {
			return "~"
		}
		if rest, found := strings.CutPrefix(path, home+"/"); found {
			return "~/" + rest
		}
	}
	return path
}

// shortText shortens the store paths inside a command or a function name:
// a store program becomes its bare name, other store paths lose the hash.
func shortText(text string) string {
	text = storeProgram.ReplaceAllString(text, "")
	return storeHashPart.ReplaceAllString(text, "")
}

// displayFunction shortens the file of an anonymous function, which zprof
// names "(anon) [<file>:<line>]".
func displayFunction(name string) string {
	if match := anonFunction.FindStringSubmatch(name); match != nil {
		return "(anon) " + shortPath(match[1]) + ":" + match[2]
	}
	return shortText(name)
}

func displayHook(name string) string {
	if name == "(prompt)" {
		return "PROMPT + RPROMPT"
	}
	return name
}

func renderReport(r renderer, report Report, savedPath string) string {
	meta := report.Meta

	var out strings.Builder
	out.WriteString(r.header("zsh startup",
		joinDot(textStyle.Render(meta.Host), textStyle.Render("zsh "+meta.ZshVersion), textStyle.Render("config "+meta.Config)),
		joinDot(mutedStyle.Render(meta.Time.Format("2006-01-02 15:04")), mutedStyle.Render(shortPath(meta.Dir))),
	))

	out.WriteString(r.section("Startup", "zsh -i -c exit", renderStats(r, report.Startup,
		fmt.Sprintf("%d runs after %d warmup", meta.Runs, meta.Warmup))))
	out.WriteString(r.section("First prompt", "precmd hooks, then prompt expansion", renderPrompt(r, report.Prompt, meta.PromptRuns)))
	functionsNote := "zprof · self time excludes callees · " + formatMs(functionTime(report.Functions)) + " in functions"
	out.WriteString(r.section("Functions", functionsNote, renderFunctions(r, report.Functions)))
	out.WriteString(r.section("Call trees", callTreesNote(report.ProfiledStartup), renderCallTrees(r, report.Functions, report.ProfiledStartup)))
	out.WriteString(r.section("Files", "xtrace · share of traced time", renderFiles(r, report.Trace)))
	out.WriteString(r.section("Slowest lines", "xtrace · share of traced time", renderLines(r, report.Trace)))
	out.WriteString(r.section("State", "left by the startup files", renderStateCounts(report.State)))

	out.WriteString("\n")
	out.WriteString(mutedStyle.Render("saved  "))
	out.WriteString(textStyle.Render(shortPath(savedPath)))
	out.WriteString("\n")
	return out.String()
}

func renderStats(r renderer, stats Stats, detail string) string {
	headline := emphasisStyle.Render(formatMs(stats.Mean)) + "  " + textStyle.Render("± "+formatMs(stats.Stddev))
	details := mutedStyle.Render(fmt.Sprintf("median %s · min %s · max %s · %s",
		formatMs(stats.Median), formatMs(stats.Min), formatMs(stats.Max), detail))
	return headline + "\n" + r.fit(details, r.contentWidth())
}

func renderPrompt(r renderer, prompt PromptCost, runs int) string {
	summary := renderStats(r, prompt.Total, fmt.Sprintf("%d shells", runs))

	rows := make([][]string, 0, len(prompt.Hooks))
	for _, hook := range prompt.Hooks {
		share := 0.0
		if prompt.Total.Mean > 0 {
			share = hook.Mean / prompt.Total.Mean
		}
		rows = append(rows, []string{textStyle.Render(displayHook(hook.Name)), textStyle.Render(formatMs(hook.Mean)), r.bar(share)})
	}

	columns := []column{{header: "step", flex: true}, {header: "time", right: true}, {header: "share"}}
	return summary + "\n\n" + r.table(columns, rows)
}

func renderFunctions(r renderer, functions []FunctionCost) string {
	if len(functions) == 0 {
		return mutedStyle.Render("zprof recorded no functions")
	}

	profiled := functionTime(functions)

	var rows [][]string
	for _, function := range functions[:min(topRows, len(functions))] {
		share := 0.0
		if profiled > 0 {
			share = function.Self / profiled
		}
		rows = append(rows, []string{
			textStyle.Render(displayFunction(function.Name)),
			mutedStyle.Render(fmt.Sprintf("%d×", function.Calls)),
			textStyle.Render(formatMs(function.Self)),
			mutedStyle.Render(formatMs(function.Total)),
			r.bar(share),
		})
	}

	columns := []column{
		{header: "function", flex: true},
		{header: "calls", right: true},
		{header: "self", right: true},
		{header: "total", right: true},
		{header: "share of self time"},
	}
	return r.table(columns, rows)
}

func callTreesNote(profiledStartup float64) string {
	note := "zprof · total includes callees · shares overlap"
	if profiledStartup > 0 {
		note += " · of " + formatMs(profiledStartup) + " profiled"
	}
	return note
}

// renderCallTrees ranks the functions that call other functions by total
// time. The share is of the profiled shell's wall time; nested functions
// count in each caller, so the shares can add up to more than 100%.
func renderCallTrees(r renderer, functions []FunctionCost, profiledStartup float64) string {
	trees := callTrees(functions)
	if len(trees) == 0 {
		return mutedStyle.Render("zprof recorded no function that calls another")
	}

	var rows [][]string
	for _, function := range trees[:min(topCallTrees, len(trees))] {
		share := mutedStyle.Render("—")
		if profiledStartup > 0 {
			share = r.bar(function.Total / profiledStartup)
		}
		rows = append(rows, []string{
			textStyle.Render(displayFunction(function.Name)),
			mutedStyle.Render(fmt.Sprintf("%d×", function.Calls)),
			textStyle.Render(formatMs(function.Total)),
			mutedStyle.Render(formatMs(function.Total - function.Self)),
			share,
		})
	}

	columns := []column{
		{header: "function", flex: true},
		{header: "calls", right: true},
		{header: "total", right: true},
		{header: "callees", right: true},
		{header: "share of profiled startup"},
	}
	return r.table(columns, rows)
}

func renderFiles(r renderer, trace TraceSummary) string {
	if trace.Total <= 0 {
		return mutedStyle.Render("xtrace recorded nothing")
	}

	var rows [][]string
	for _, file := range trace.Files[:min(topRows, len(trace.Files))] {
		rows = append(rows, []string{
			textStyle.Render(shortPath(file.Path)),
			mutedStyle.Render(fmt.Sprint(file.Lines)),
			r.bar(file.Time / trace.Total),
		})
	}

	columns := []column{{header: "file", flex: true, cutLeft: true}, {header: "lines", right: true}, {header: "share"}}
	return r.table(columns, rows)
}

func renderLines(r renderer, trace TraceSummary) string {
	if trace.Total <= 0 {
		return mutedStyle.Render("xtrace recorded nothing")
	}

	var rows [][]string
	for _, line := range trace.Slowest[:min(topRows, len(trace.Slowest))] {
		location := fmt.Sprintf("%s:%d", shortPath(line.Path), line.Line)
		rows = append(rows, []string{
			textStyle.Render(formatShare(line.Time / trace.Total)),
			mutedStyle.Render(location),
			textStyle.Render(shortText(strings.TrimSpace(line.Command))),
		})
	}

	columns := []column{
		{header: "share", right: true},
		{header: "location", flex: true, cutLeft: true},
		{header: "command", flex: true},
	}
	return r.table(columns, rows)
}

func renderStateCounts(state State) string {
	var parts []string
	for _, category := range stateCategories {
		parts = append(parts, emphasisStyle.Render(fmt.Sprint(len(state[category])))+" "+textStyle.Render(category))
	}
	return joinDot(parts...)
}

func renderComparison(r renderer, comparison Comparison, savedPath string) string {
	old := comparison.Old.Meta
	new := comparison.New.Meta

	side := func(label, name string, meta Meta) string {
		return labelStyle.Render(label) + "  " + joinDot(
			textStyle.Render(name),
			mutedStyle.Render(meta.Time.Format("2006-01-02 15:04")),
			textStyle.Render("config "+meta.Config),
		)
	}

	var out strings.Builder
	out.WriteString(r.header("zsh startup · compare",
		side("old", comparison.OldName, old),
		side("new", comparison.NewName, new),
	))
	for _, warning := range comparison.Warnings {
		out.WriteString(r.wrap(warningStyle, "! "+warning))
		out.WriteString("\n")
	}

	out.WriteString(r.section("Startup", "mean", renderDelta(comparison.Startup)))
	out.WriteString(r.section("First prompt", "mean", renderDelta(comparison.Prompt)+"\n\n"+renderHookDeltas(r, comparison.Hooks)))
	functionsNote := fmt.Sprintf("zprof · largest self time changes · %s → %s in functions",
		formatMs(functionTime(comparison.Old.Functions)), formatMs(functionTime(comparison.New.Functions)))
	out.WriteString(r.section("Functions", functionsNote, renderFunctionDeltas(r, comparison.Functions)))
	out.WriteString(r.section("Call trees", "zprof · largest total time changes · total includes callees", renderCallTreeDeltas(r, comparison.CallTrees)))
	out.WriteString(r.section("State", "entries added, removed, or changed", renderStateDeltas(r, comparison.State)))

	if savedPath != "" {
		out.WriteString("\n")
		out.WriteString(mutedStyle.Render("saved  "))
		out.WriteString(textStyle.Render(shortPath(savedPath)))
		out.WriteString("\n")
	}
	return out.String()
}

func renderDelta(delta Delta) string {
	values := textStyle.Render(formatMs(delta.Old)) + mutedStyle.Render("  →  ") + emphasisStyle.Render(formatMs(delta.New))

	if delta.Noise {
		note := fmt.Sprintf("within noise (±%s)", formatMs(delta.Threshold))
		return values + "    " + mutedStyle.Render(note)
	}

	percent := fmt.Sprintf("%+.1f%%", delta.Percent)
	percent = strings.Replace(percent, "-", "−", 1)
	style := worseStyle
	if delta.Diff < 0 {
		style = betterStyle
	}
	return values + "    " + formatChange(delta.Diff) + "  " + style.Render(percent)
}

func optionalMs(value float64, present bool) string {
	if !present {
		return mutedStyle.Render("—")
	}
	return textStyle.Render(formatMs(value))
}

func renderHookDeltas(r renderer, hooks []HookDelta) string {
	var rows [][]string
	for _, hook := range hooks {
		rows = append(rows, []string{
			textStyle.Render(displayHook(hook.Name)),
			optionalMs(hook.Old, hook.InOld),
			optionalMs(hook.New, hook.InNew),
			formatChange(hook.New - hook.Old),
		})
	}

	columns := []column{{header: "step", flex: true}, {header: "old", right: true}, {header: "new", right: true}, {header: "change", right: true}}
	return r.table(columns, rows)
}

func renderFunctionDeltas(r renderer, functions []FunctionDelta) string {
	if len(functions) == 0 {
		return mutedStyle.Render("zprof recorded no functions")
	}

	var rows [][]string
	for _, function := range functions {
		rows = append(rows, []string{
			textStyle.Render(displayFunction(function.Name)),
			mutedStyle.Render(formatCalls(function.OldCalls, function.InOld) + " → " + formatCalls(function.NewCalls, function.InNew)),
			pairNumbers(function.OldSelf, function.InOld, function.NewSelf, function.InNew),
			formatChangeNumber(function.NewSelf - function.OldSelf),
			pairNumbers(function.OldTotal, function.InOld, function.NewTotal, function.InNew),
			formatChangeNumber(function.NewTotal - function.OldTotal),
		})
	}

	// Old and new values share one cell so that the table fits narrow terminals.
	columns := []column{
		{header: "function", flex: true},
		{header: "calls", right: true},
		{header: "self ms", right: true},
		{header: "Δ", right: true},
		{header: "total ms", right: true},
		{header: "Δ", right: true},
	}
	return r.table(columns, rows)
}

func renderCallTreeDeltas(r renderer, trees []FunctionDelta) string {
	if len(trees) == 0 {
		return mutedStyle.Render("zprof recorded no function that calls another")
	}

	var rows [][]string
	for _, tree := range trees {
		rows = append(rows, []string{
			textStyle.Render(displayFunction(tree.Name)),
			mutedStyle.Render(formatCalls(tree.OldCalls, tree.InOld) + " → " + formatCalls(tree.NewCalls, tree.InNew)),
			pairNumbers(tree.OldTotal, tree.InOld, tree.NewTotal, tree.InNew),
			formatChangeNumber(tree.NewTotal - tree.OldTotal),
		})
	}

	columns := []column{
		{header: "function", flex: true},
		{header: "calls", right: true},
		{header: "total ms", right: true},
		{header: "Δ", right: true},
	}
	return r.table(columns, rows)
}

// formatCalls shows a zprof call count; a dash marks a report without the function.
func formatCalls(count int, present bool) string {
	if !present {
		return "—"
	}
	return fmt.Sprintf("%d×", count)
}

// pairNumbers shows "old → new"; a dash marks a side that lacks the value.
func pairNumbers(old float64, inOld bool, new float64, inNew bool) string {
	side := func(value float64, present bool) string {
		if !present {
			return mutedStyle.Render("—")
		}
		return textStyle.Render(formatNumber(value))
	}
	return side(old, inOld) + mutedStyle.Render(" → ") + side(new, inNew)
}

func renderStateDeltas(r renderer, deltas []StateDelta) string {
	var blocks []string
	for _, delta := range deltas {
		if len(delta.Added)+len(delta.Removed)+len(delta.Changed) == 0 {
			continue
		}

		counts := joinDot(
			addedStyle.Render(fmt.Sprintf("+%d", len(delta.Added))),
			removedStyle.Render(fmt.Sprintf("−%d", len(delta.Removed))),
			textStyle.Render(fmt.Sprintf("~%d", len(delta.Changed))),
		)
		lines := []string{labelStyle.Render(delta.Category) + "  " + counts}
		lines = appendNames(r, lines, "+", addedStyle, delta.Added)
		lines = appendNames(r, lines, "−", removedStyle, delta.Removed)
		lines = appendNames(r, lines, "~", textStyle, delta.Changed)
		blocks = append(blocks, strings.Join(lines, "\n"))
	}

	if len(blocks) == 0 {
		return mutedStyle.Render("no changes")
	}
	return strings.Join(blocks, "\n\n")
}

// appendNames adds one line that lists names, cut to the width with a count
// of the names that did not fit. A first name that is wider than the line is
// cut, so that the line shows at least one name.
func appendNames(r renderer, lines []string, sign string, style lipgloss.Style, names []string) []string {
	if len(names) == 0 {
		return lines
	}

	available := r.contentWidth() - len(indent) - 2
	var shown []string
	used := 0
	for i, name := range names {
		hidden := len(names) - i

		// Every name but the last leaves room for "… <hidden> more", so that
		// the count fits when the next name does not.
		room := available - used
		if hidden > 1 {
			room -= lipgloss.Width(fmt.Sprintf(" … %d more", hidden))
		}

		if lipgloss.Width(name) > room {
			if len(shown) > 0 {
				shown = append(shown, mutedStyle.Render(fmt.Sprintf("… %d more", hidden)))
				break
			}
			name = cut(name, max(room, 1), false)
		}
		shown = append(shown, style.Render(name))
		used += lipgloss.Width(name) + 1
	}
	return append(lines, indent+style.Render(sign)+" "+strings.Join(shown, " "))
}
