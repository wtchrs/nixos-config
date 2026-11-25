package main

import (
	"encoding/json"
	"math"
	"slices"
	"strings"
	"testing"
	"time"
)

func TestComputeStats(t *testing.T) {
	stats := computeStats([]float64{3, 1, 2, 4})

	if !near(stats.Mean, 2.5) || !near(stats.Median, 2.5) || stats.Min != 1 || stats.Max != 4 {
		t.Errorf("stats = %+v", stats)
	}
	if !near(stats.Stddev, math.Sqrt(5.0/3.0)) {
		t.Errorf("Stddev = %v, want sample standard deviation %v", stats.Stddev, math.Sqrt(5.0/3.0))
	}
}

func TestCompareStatsTellsNoiseFromChange(t *testing.T) {
	samples := make([]float64, 20)
	old := Stats{Mean: 240, Stddev: 10, Samples: samples}

	small := compareStats(old, Stats{Mean: 236, Stddev: 10, Samples: samples})
	if !small.Noise {
		t.Errorf("a 4 ms change with a 6.3 ms threshold should be noise: %+v", small)
	}

	large := compareStats(old, Stats{Mean: 130, Stddev: 10, Samples: samples})
	if large.Noise {
		t.Errorf("a 110 ms change should not be noise: %+v", large)
	}
	if !near(large.Diff, -110) || !near(large.Percent, -110.0/240*100) {
		t.Errorf("Diff = %v, Percent = %v", large.Diff, large.Percent)
	}
}

func TestCompareStateFindsAddedRemovedAndChanged(t *testing.T) {
	old := State{"aliases": {"md": "mkdir", "gst": "git status", "ll": "ls -l"}}
	new := State{"aliases": {"gst": "git status", "ll": "lsd -l", "zi": "zoxide"}}

	deltas := compareState(old, new)

	aliases := deltas[slices.Index(stateCategories, "aliases")]
	if !slices.Equal(aliases.Added, []string{"zi"}) {
		t.Errorf("Added = %v", aliases.Added)
	}
	if !slices.Equal(aliases.Removed, []string{"md"}) {
		t.Errorf("Removed = %v", aliases.Removed)
	}
	if !slices.Equal(aliases.Changed, []string{"ll"}) {
		t.Errorf("Changed = %v", aliases.Changed)
	}
}

func TestCompareHooksKeepsRemovedHooks(t *testing.T) {
	old := []HookCost{{Name: "a", Mean: 1}, {Name: "gone", Mean: 2}}
	new := []HookCost{{Name: "a", Mean: 3}, {Name: "fresh", Mean: 4}}

	deltas := compareHooks(old, new)

	names := []string{}
	for _, delta := range deltas {
		names = append(names, delta.Name)
	}
	if !slices.Equal(names, []string{"a", "fresh", "gone"}) {
		t.Errorf("order = %v", names)
	}
	if deltas[1].InOld || !deltas[2].InOld || deltas[2].InNew {
		t.Errorf("presence flags = %+v", deltas)
	}
}

func TestCompareFunctionsCarriesSelfAndTotal(t *testing.T) {
	old := []FunctionCost{
		{Name: "compinit", Calls: 2, Self: 18, Total: 82},
		{Name: "_omz_source", Calls: 23, Self: 15, Total: 18},
	}
	new := []FunctionCost{
		{Name: "compinit", Calls: 1, Self: 9, Total: 41},
	}

	deltas := compareFunctions(old, new)

	if len(deltas) != 2 || deltas[0].Name != "_omz_source" {
		t.Fatalf("deltas = %+v, want _omz_source (largest self change) first", deltas)
	}
	removed := deltas[0]
	if !removed.InOld || removed.InNew || removed.OldTotal != 18 {
		t.Errorf("removed function = %+v", removed)
	}
	compinit := deltas[1]
	if compinit.OldTotal != 82 || compinit.NewTotal != 41 || compinit.OldCalls != 2 || compinit.NewCalls != 1 {
		t.Errorf("compinit = %+v", compinit)
	}
}

func TestCallTreesKeepsFunctionsWithCallees(t *testing.T) {
	functions := []FunctionCost{
		{Name: "compaudit", Self: 64, Total: 64},
		{Name: "_omz_source", Self: 15, Total: 18},
		{Name: "rounded", Self: 1.004, Total: 1.008},
		{Name: "compinit", Self: 18, Total: 82},
	}

	trees := callTrees(functions)

	names := []string{}
	for _, tree := range trees {
		names = append(names, tree.Name)
	}
	if !slices.Equal(names, []string{"compinit", "_omz_source"}) {
		t.Errorf("call trees = %v, want compinit then _omz_source", names)
	}
}

func TestCompareCallTreesRanksTotalChanges(t *testing.T) {
	old := []FunctionCost{
		{Name: "compinit", Calls: 2, Self: 18, Total: 82},
		{Name: "compaudit", Calls: 4, Self: 64, Total: 64},
		{Name: "wrapper", Calls: 1, Self: 1, Total: 3},
	}
	new := []FunctionCost{
		{Name: "compinit", Calls: 1, Self: 9, Total: 41},
		{Name: "compaudit", Calls: 2, Self: 32, Total: 32},
		// wrapper no longer calls anything, but it had callees before.
		{Name: "wrapper", Calls: 1, Self: 1, Total: 1},
	}

	trees := compareCallTrees(old, new)

	names := []string{}
	for _, tree := range trees {
		names = append(names, tree.Name)
	}
	if !slices.Equal(names, []string{"compinit", "wrapper"}) {
		t.Errorf("call tree changes = %v, want compinit then wrapper (compaudit has no callees)", names)
	}
}

func TestFunctionTimeSumsSelfTimes(t *testing.T) {
	functions := []FunctionCost{{Self: 18, Total: 82}, {Self: 64, Total: 64}}
	if got := functionTime(functions); got != 82 {
		t.Errorf("functionTime = %v, want 82 (self times only)", got)
	}
}

func TestComparisonOutputLeavesOutTheReports(t *testing.T) {
	old := Report{
		Meta:      Meta{Host: "box", Config: "1111"},
		Functions: []FunctionCost{{Name: "compinit", Calls: 2, Self: 18, Total: 82}},
		State:     State{"aliases": {"md": "mkdir"}},
	}
	new := Report{
		Meta:      Meta{Host: "box", Config: "2222"},
		Functions: []FunctionCost{{Name: "compinit", Calls: 1, Self: 9, Total: 41}},
		State:     State{"aliases": {"md": "mkdir"}},
	}
	comparison := compareReports(old, new, "old.json", "measured now")

	data, err := encodeJSON(comparisonOutput(comparison, "/tmp/old.json", "/tmp/new.json"))
	if err != nil {
		t.Fatal(err)
	}

	var decoded map[string]any
	err = json.Unmarshal(data, &decoded)
	if err != nil {
		t.Fatal(err)
	}

	var keys []string
	for key := range decoded {
		keys = append(keys, key)
	}
	slices.Sort(keys)
	want := []string{"call_trees", "function_time", "functions", "hooks", "new", "old", "prompt", "schema", "startup", "state", "warnings"}
	if !slices.Equal(keys, want) {
		t.Errorf("top-level keys = %v, want %v", keys, want)
	}

	identity := decoded["old"].(map[string]any)
	if identity["path"] != "/tmp/old.json" || identity["name"] != "old.json" {
		t.Errorf("old identity = %v", identity)
	}
	if _, embedded := identity["functions"]; embedded {
		t.Error("the old report is embedded in the comparison")
	}

	// Empty lists must stay lists for JSON consumers.
	if hooks, ok := decoded["hooks"].([]any); !ok || len(hooks) != 0 {
		t.Errorf("hooks = %#v, want []", decoded["hooks"])
	}
	firstState := decoded["state"].([]any)[0].(map[string]any)
	if added, ok := firstState["added"].([]any); !ok || len(added) != 0 {
		t.Errorf("state added = %#v, want []", firstState["added"])
	}

	functionTime := decoded["function_time"].(map[string]any)
	if functionTime["old"] != 18.0 || functionTime["new"] != 9.0 {
		t.Errorf("function_time = %v", functionTime)
	}
}

func TestComparisonWarnings(t *testing.T) {
	base := Meta{Host: "a", ZshVersion: "5.9", Config: "1111", Term: "xterm-ghostty", Terminal: true, Time: time.Now()}

	other := base
	other.Config = "2222"
	if warnings := comparisonWarnings(base, other); len(warnings) != 0 {
		t.Errorf("same context, new config: warnings = %v", warnings)
	}

	if warnings := comparisonWarnings(base, base); len(warnings) != 1 || !strings.Contains(warnings[0], "same configuration") {
		t.Errorf("same config: warnings = %v", warnings)
	}

	piped := other
	piped.Terminal = false
	warnings := comparisonWarnings(base, piped)
	if len(warnings) != 1 || !strings.Contains(warnings[0], "without tty") {
		t.Errorf("different terminal: warnings = %v", warnings)
	}
}
