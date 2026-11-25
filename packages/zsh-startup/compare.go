package main

import (
	"cmp"
	"fmt"
	"math"
	"slices"
)

// keepFunctionDeltas and keepCallTreeDeltas are how many function changes a
// comparison shows in each table.
const (
	keepFunctionDeltas = 10
	keepCallTreeDeltas = 8
)

type Comparison struct {
	Old, New         Report
	OldName, NewName string
	Warnings         []string
	Startup          Delta
	Prompt           Delta
	Hooks            []HookDelta
	Functions        []FunctionDelta
	CallTrees        []FunctionDelta
	State            []StateDelta
}

// Delta compares two measurements. Threshold is two standard errors of the
// difference of the means; a smaller difference is noise.
type Delta struct {
	Old       float64 `json:"old"`
	New       float64 `json:"new"`
	Diff      float64 `json:"diff"`
	Percent   float64 `json:"percent"`
	Threshold float64 `json:"threshold"`
	Noise     bool    `json:"noise"`
	// Estimated is false when a side has fewer than two samples. Such a side
	// has no spread, so Threshold and Noise stay unset.
	Estimated bool `json:"estimated"`
}

type HookDelta struct {
	Name string  `json:"name"`
	Old  float64 `json:"old"`
	New  float64 `json:"new"`
	// InOld and InNew tell an absent hook from a hook that took 0 ms.
	InOld bool `json:"in_old"`
	InNew bool `json:"in_new"`
}

type FunctionDelta struct {
	Name     string  `json:"name"`
	OldCalls int     `json:"old_calls"`
	NewCalls int     `json:"new_calls"`
	OldSelf  float64 `json:"old_self"`
	NewSelf  float64 `json:"new_self"`
	OldTotal float64 `json:"old_total"`
	NewTotal float64 `json:"new_total"`
	InOld    bool    `json:"in_old"`
	InNew    bool    `json:"in_new"`
}

type StateDelta struct {
	Category string   `json:"category"`
	Added    []string `json:"added"`
	Removed  []string `json:"removed"`
	Changed  []string `json:"changed"`
}

// compareSchemaVersion changes when the compare JSON layout changes
// incompatibly. It is separate from the report schema.
const compareSchemaVersion = 1

// ComparisonOutput is the JSON form of a comparison for --json. It leaves out
// the two reports, which exist as files, and keeps what identifies them.
type ComparisonOutput struct {
	Schema       int             `json:"schema"`
	Old          ReportIdentity  `json:"old"`
	New          ReportIdentity  `json:"new"`
	Warnings     []string        `json:"warnings"`
	Startup      Delta           `json:"startup"`
	Prompt       Delta           `json:"prompt"`
	Hooks        []HookDelta     `json:"hooks"`
	FunctionTime FunctionTime    `json:"function_time"`
	Functions    []FunctionDelta `json:"functions"`
	CallTrees    []FunctionDelta `json:"call_trees"`
	State        []StateDelta    `json:"state"`
}

type ReportIdentity struct {
	Name string `json:"name"`
	// Path is the report file; for a new measurement, the file it was saved to.
	Path string `json:"path"`
	Meta Meta   `json:"meta"`
}

// FunctionTime is the time spent inside functions in each report. It comes
// from one zprof run per report, so it has no noise estimate.
type FunctionTime struct {
	Old float64 `json:"old"`
	New float64 `json:"new"`
}

func comparisonOutput(comparison Comparison, oldPath, newPath string) ComparisonOutput {
	return ComparisonOutput{
		Schema:   compareSchemaVersion,
		Old:      ReportIdentity{Name: comparison.OldName, Path: oldPath, Meta: comparison.Old.Meta},
		New:      ReportIdentity{Name: comparison.NewName, Path: newPath, Meta: comparison.New.Meta},
		Warnings: emptyIfNil(comparison.Warnings),
		Startup:  comparison.Startup,
		Prompt:   comparison.Prompt,
		Hooks:    emptyIfNil(comparison.Hooks),
		FunctionTime: FunctionTime{
			Old: functionTime(comparison.Old.Functions),
			New: functionTime(comparison.New.Functions),
		},
		Functions: emptyIfNil(comparison.Functions),
		CallTrees: emptyIfNil(comparison.CallTrees),
		State:     emptyIfNil(comparison.State),
	}
}

// emptyIfNil makes an empty list encode as [] instead of null.
func emptyIfNil[T any](items []T) []T {
	if items == nil {
		return []T{}
	}
	return items
}

func compareReports(old, new Report, oldName, newName string) Comparison {
	return Comparison{
		Old:       old,
		New:       new,
		OldName:   oldName,
		NewName:   newName,
		Warnings:  comparisonWarnings(old.Meta, new.Meta),
		Startup:   compareStats(old.Startup, new.Startup),
		Prompt:    compareStats(old.Prompt.Total, new.Prompt.Total),
		Hooks:     compareHooks(old.Prompt.Hooks, new.Prompt.Hooks),
		Functions: compareFunctions(old.Functions, new.Functions),
		CallTrees: compareCallTrees(old.Functions, new.Functions),
		State:     compareState(old.State, new.State),
	}
}

func comparisonWarnings(old, new Meta) []string {
	var warnings []string
	if old.Host != new.Host {
		warnings = append(warnings, "different hosts: "+old.Host+" → "+new.Host)
	}
	if old.ZshVersion != new.ZshVersion {
		warnings = append(warnings, "different zsh versions: "+old.ZshVersion+" → "+new.ZshVersion)
	}
	if old.Term != new.Term || old.Terminal != new.Terminal {
		warnings = append(warnings, fmt.Sprintf(
			"different terminals: %s → %s; key bindings and options can differ",
			terminalLabel(old), terminalLabel(new),
		))
	}
	if old.Config == new.Config {
		warnings = append(warnings, "same configuration ("+new.Config+"): the startup files did not change, so differences are likely run-to-run variation")
	}
	return warnings
}

func terminalLabel(meta Meta) string {
	term := meta.Term
	if term == "" {
		term = "no TERM"
	}
	if meta.Terminal {
		return term + " with tty"
	}
	return term + " without tty"
}

func compareStats(old, new Stats) Delta {
	diff := new.Mean - old.Mean

	percent := 0.0
	if old.Mean != 0 {
		percent = diff / old.Mean * 100
	}

	delta := Delta{
		Old:     old.Mean,
		New:     new.Mean,
		Diff:    diff,
		Percent: percent,
	}

	estimated := len(old.Samples) >= 2 && len(new.Samples) >= 2
	if estimated {
		delta.Estimated = true
		delta.Threshold = 2 * standardError(old, new)
		delta.Noise = math.Abs(diff) < delta.Threshold
	}
	return delta
}

func standardError(old, new Stats) float64 {
	variance := 0.0
	if count := len(old.Samples); count > 0 {
		variance += old.Stddev * old.Stddev / float64(count)
	}
	if count := len(new.Samples); count > 0 {
		variance += new.Stddev * new.Stddev / float64(count)
	}
	return math.Sqrt(variance)
}

// compareHooks keeps the execution order of the new report, then appends
// hooks that only the old report has.
func compareHooks(old, new []HookCost) []HookDelta {
	oldByName := map[string]float64{}
	for _, hook := range old {
		oldByName[hook.Name] = hook.Mean
	}

	var deltas []HookDelta
	inNew := map[string]bool{}
	for _, hook := range new {
		oldMean, found := oldByName[hook.Name]
		deltas = append(deltas, HookDelta{Name: hook.Name, Old: oldMean, New: hook.Mean, InOld: found, InNew: true})
		inNew[hook.Name] = true
	}
	for _, hook := range old {
		if !inNew[hook.Name] {
			deltas = append(deltas, HookDelta{Name: hook.Name, Old: hook.Mean, InOld: true})
		}
	}
	return deltas
}

// compareFunctions returns the functions whose self time changed most.
func compareFunctions(old, new []FunctionCost) []FunctionDelta {
	deltas := mergeFunctions(old, new)
	slices.SortStableFunc(deltas, func(a, b FunctionDelta) int {
		return cmp.Compare(math.Abs(b.NewSelf-b.OldSelf), math.Abs(a.NewSelf-a.OldSelf))
	})
	return deltas[:min(keepFunctionDeltas, len(deltas))]
}

// compareCallTrees returns the functions with callees whose total time
// changed most. A function counts when it has callees in either report.
func compareCallTrees(old, new []FunctionCost) []FunctionDelta {
	var trees []FunctionDelta
	for _, delta := range mergeFunctions(old, new) {
		oldHasCallees := delta.InOld && hasCallees(delta.OldSelf, delta.OldTotal)
		newHasCallees := delta.InNew && hasCallees(delta.NewSelf, delta.NewTotal)
		if oldHasCallees || newHasCallees {
			trees = append(trees, delta)
		}
	}
	slices.SortStableFunc(trees, func(a, b FunctionDelta) int {
		return cmp.Compare(math.Abs(b.NewTotal-b.OldTotal), math.Abs(a.NewTotal-a.OldTotal))
	})
	return trees[:min(keepCallTreeDeltas, len(trees))]
}

// mergeFunctions pairs the functions of two reports by name, in the order
// they first appear.
func mergeFunctions(old, new []FunctionCost) []FunctionDelta {
	byName := map[string]*FunctionDelta{}
	var names []string

	entry := func(name string) *FunctionDelta {
		delta, found := byName[name]
		if !found {
			delta = &FunctionDelta{Name: name}
			byName[name] = delta
			names = append(names, name)
		}
		return delta
	}

	for _, function := range old {
		delta := entry(function.Name)
		delta.OldCalls = function.Calls
		delta.OldSelf = function.Self
		delta.OldTotal = function.Total
		delta.InOld = true
	}
	for _, function := range new {
		delta := entry(function.Name)
		delta.NewCalls = function.Calls
		delta.NewSelf = function.Self
		delta.NewTotal = function.Total
		delta.InNew = true
	}

	deltas := make([]FunctionDelta, 0, len(names))
	for _, name := range names {
		deltas = append(deltas, *byName[name])
	}
	return deltas
}

func compareState(old, new State) []StateDelta {
	var deltas []StateDelta
	for _, category := range stateCategories {
		oldEntries := old[category]
		newEntries := new[category]
		delta := StateDelta{Category: category, Added: []string{}, Removed: []string{}, Changed: []string{}}

		for key, newValue := range newEntries {
			oldValue, found := oldEntries[key]
			if !found {
				delta.Added = append(delta.Added, key)
			} else if oldValue != newValue {
				delta.Changed = append(delta.Changed, key)
			}
		}
		for key := range oldEntries {
			if _, found := newEntries[key]; !found {
				delta.Removed = append(delta.Removed, key)
			}
		}

		slices.Sort(delta.Added)
		slices.Sort(delta.Removed)
		slices.Sort(delta.Changed)
		deltas = append(deltas, delta)
	}
	return deltas
}
