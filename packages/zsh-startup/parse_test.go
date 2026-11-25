package main

import (
	"math"
	"strings"
	"testing"
)

func near(a, b float64) bool {
	return math.Abs(a-b) < 1e-6
}

func TestParseZprofReadsOnlyTheFirstTable(t *testing.T) {
	output := `num  calls                time                       self            name
-----------------------------------------------------------------------------------
 1)    2          81.01    40.50   57.46%     16.32     8.16   11.58%  compinit
 2)    4          64.69    16.17   45.89%     64.69    16.17   45.89%  compaudit
 3)    1           2.73     2.73    1.93%      2.70     2.70    1.92%  (anon) [/etc/zshrc:12]

-----------------------------------------------------------------------------------

 1)    2          81.01    40.50   57.46%     16.32     8.16   11.58%  compinit
       4/4        64.69    16.17   45.89%     64.69    16.17             compaudit [2]
`

	functions := parseZprof(output)

	if len(functions) != 3 {
		t.Fatalf("got %d functions, want 3: %+v", len(functions), functions)
	}
	// Sorted by self time, highest first.
	if functions[0].Name != "compaudit" || functions[0].Calls != 4 || !near(functions[0].Self, 64.69) {
		t.Errorf("first function = %+v, want compaudit with 4 calls and 64.69 ms self", functions[0])
	}
	if functions[1].Name != "compinit" || !near(functions[1].Total, 81.01) || !near(functions[1].Self, 16.32) {
		t.Errorf("second function = %+v, want compinit with 81.01 ms total and 16.32 ms self", functions[1])
	}
	if functions[2].Name != "(anon) [/etc/zshrc:12]" {
		t.Errorf("third function name = %q", functions[2].Name)
	}
}

func traceLine(at, path, line, command string) string {
	return "+" + strings.Join([]string{at, path, line, command}, traceSeparator)
}

func TestParseTraceChargesEachLineUntilTheNext(t *testing.T) {
	output := strings.Join([]string{
		"zsh: some warning",
		traceLine("1000.000000", "/a", "1", "first"),
		traceLine("1000.010000", "/a", "2", "slow"),
		"  rest of a multi-line command",
		traceLine("1000.040000", "/b", "1", "third"),
		traceLine("1000.050000", "/a", "3", "exit"),
	}, "\n")

	trace := parseTrace(output, 10)

	if trace.Lines != 4 {
		t.Errorf("Lines = %d, want 4", trace.Lines)
	}
	if !near(trace.Total, 50) {
		t.Errorf("Total = %v ms, want 50", trace.Total)
	}

	if len(trace.Files) != 2 || trace.Files[0].Path != "/a" || !near(trace.Files[0].Time, 40) {
		t.Fatalf("Files = %+v, want /a with 40 ms first", trace.Files)
	}
	if trace.Files[1].Path != "/b" || !near(trace.Files[1].Time, 10) {
		t.Errorf("second file = %+v, want /b with 10 ms", trace.Files[1])
	}

	slowest := trace.Slowest[0]
	if slowest.Path != "/a" || slowest.Line != 2 || slowest.Command != "slow" || !near(slowest.Time, 30) {
		t.Errorf("slowest line = %+v, want /a:2 slow with 30 ms", slowest)
	}
}

func TestParseTraceShortensLongCommands(t *testing.T) {
	long := "_i_files=( " + strings.Repeat("/nix/store/path/_completion ", 1000) + ")"
	output := strings.Join([]string{
		traceLine("1.0", "/compaudit", "62", long),
		traceLine("1.5", "/compaudit", "63", "short"),
	}, "\n")

	trace := parseTrace(output, 10)

	command := trace.Slowest[0].Command
	if len([]rune(command)) != maxCommandLength+1 || !strings.HasSuffix(command, "…") {
		t.Errorf("command has %d runes, want %d ending with an ellipsis", len([]rune(command)), maxCommandLength+1)
	}
	if !strings.HasPrefix(command, "_i_files=( ") {
		t.Errorf("command lost its start: %q", command[:20])
	}
}

func TestParseTraceKeepsTheRequestedRows(t *testing.T) {
	output := strings.Join([]string{
		traceLine("1.0", "/a", "1", "one"),
		traceLine("1.1", "/b", "1", "two"),
		traceLine("1.2", "/c", "1", "three"),
		traceLine("1.3", "/d", "1", "four"),
	}, "\n")

	trace := parseTrace(output, 2)

	if len(trace.Files) != 2 || len(trace.Slowest) != 2 {
		t.Errorf("got %d files and %d lines, want 2 and 2", len(trace.Files), len(trace.Slowest))
	}
}

func TestParseStateSplitsKeysAndValues(t *testing.T) {
	output := `output of a startup file
@@aliases
gst='git status'
ll='lsd -l'
@@bindkeys
bindkey "^A" beginning-of-line
bindkey -R "!"-"~" self-insert
bindkey -s "^Xa" "foo bar"
bindkey -s "^Xb" "say \"hi\" x"
bindkey "\" x" self-insert
@@options
autocd
sharehistory
@@zstyles
':completion:*' menu` + "\t" + `yes select
':completion:*:descriptions' format` + "\t" + `'%B%d%b'
`

	state := parseState(output)

	if got := state["aliases"]["gst"]; got != "'git status'" {
		t.Errorf("alias gst = %q", got)
	}
	if got := state["bindkeys"][`"^A"`]; got != "beginning-of-line" {
		t.Errorf(`bindkey "^A" = %q`, got)
	}
	if got := state["bindkeys"][`-R "!"-"~"`]; got != "self-insert" {
		t.Errorf("range bindkey = %q", got)
	}
	if got := state["bindkeys"][`"^Xa"`]; got != `-s "foo bar"` {
		t.Errorf(`string bindkey "^Xa" = %q`, got)
	}
	if got := state["bindkeys"][`"^Xb"`]; got != `-s "say \"hi\" x"` {
		t.Errorf(`string bindkey "^Xb" = %q`, got)
	}
	if got := state["bindkeys"][`"\" x"`]; got != "self-insert" {
		t.Errorf(`bindkey "\" x" = %q`, got)
	}
	if _, found := state["options"]["sharehistory"]; !found {
		t.Error("option sharehistory missing")
	}
	if got := state["zstyles"]["':completion:*' menu"]; got != "yes select" {
		t.Errorf("zstyle menu = %q", got)
	}
	if len(state["zstyles"]) != 2 {
		t.Errorf("zstyles = %v, want two entries", state["zstyles"])
	}
	for _, category := range stateCategories {
		if _, found := state[category]; !found {
			t.Errorf("category %s missing", category)
		}
	}
}

func TestParsePromptRunKeepsOrder(t *testing.T) {
	output := "title escape\n@@_direnv_hook\t5.25\nnoise\n@@(prompt)\t13.5\n@@broken\n"

	hooks := parsePromptRun(output)

	if len(hooks) != 2 {
		t.Fatalf("hooks = %+v, want 2", hooks)
	}
	if hooks[0].Name != "_direnv_hook" || !near(hooks[0].Mean, 5.25) {
		t.Errorf("first hook = %+v", hooks[0])
	}
	if hooks[1].Name != "(prompt)" || !near(hooks[1].Mean, 13.5) {
		t.Errorf("second hook = %+v", hooks[1])
	}
}
