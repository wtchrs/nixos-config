package main

import (
	"cmp"
	"math"
	"slices"
	"time"
)

// schemaVersion changes when the JSON layout changes incompatibly.
// compare refuses reports with a different version.
const schemaVersion = 1

// All durations are in milliseconds.

type Report struct {
	Schema    int            `json:"schema"`
	Meta      Meta           `json:"meta"`
	Startup   Stats          `json:"startup"`
	Prompt    PromptCost     `json:"prompt"`
	Functions []FunctionCost `json:"functions"`
	// ProfiledStartup is the wall time of the shell that zprof profiled.
	// Older reports lack it and load it as 0.
	ProfiledStartup float64      `json:"profiled_startup"`
	Trace           TraceSummary `json:"trace"`
	State           State        `json:"state"`
}

type Meta struct {
	Time       time.Time `json:"time"`
	Host       string    `json:"host"`
	Dir        string    `json:"dir"`
	ZshPath    string    `json:"zsh_path"`
	ZshVersion string    `json:"zsh_version"`
	// Term and Terminal describe the terminal context. Key bindings read from
	// terminfo depend on TERM, and options such as monitor depend on whether
	// the shells had a controlling terminal.
	Term     string `json:"term"`
	Terminal bool   `json:"terminal"`
	// Config is a short hash of the user's .zshenv and .zshrc contents.
	// Equal hashes mean the two reports measured the same configuration.
	Config     string `json:"config"`
	Runs       int    `json:"runs"`
	Warmup     int    `json:"warmup"`
	PromptRuns int    `json:"prompt_runs"`
}

type Stats struct {
	Mean    float64   `json:"mean"`
	Stddev  float64   `json:"stddev"`
	Median  float64   `json:"median"`
	Min     float64   `json:"min"`
	Max     float64   `json:"max"`
	Samples []float64 `json:"samples"`
}

// PromptCost is the cost of drawing the first prompt: each precmd hook in
// execution order, then the expansion of PROMPT and RPROMPT.
type PromptCost struct {
	Total Stats      `json:"total"`
	Hooks []HookCost `json:"hooks"`
}

type HookCost struct {
	Name string  `json:"name"`
	Mean float64 `json:"mean"`
}

// FunctionCost is one row of the zprof table.
type FunctionCost struct {
	Name  string  `json:"name"`
	Calls int     `json:"calls"`
	Total float64 `json:"total"`
	Self  float64 `json:"self"`
}

// TraceSummary comes from one xtrace run. Tracing slows the shell down,
// so only the shares of Total are meaningful, not the absolute times.
type TraceSummary struct {
	Total   float64    `json:"total"`
	Lines   int        `json:"lines"`
	Files   []FileCost `json:"files"`
	Slowest []LineCost `json:"slowest"`
}

type FileCost struct {
	Path  string  `json:"path"`
	Time  float64 `json:"time"`
	Lines int     `json:"lines"`
}

type LineCost struct {
	Path    string  `json:"path"`
	Line    int     `json:"line"`
	Command string  `json:"command"`
	Time    float64 `json:"time"`
}

// State maps a category (see stateCategories) to its entries.
// Each entry maps a key, such as an alias name, to its value.
type State map[string]map[string]string

// stateCategories fixes the display order of the State categories.
var stateCategories = []string{"aliases", "bindkeys", "options", "zstyles"}

// functionTime is the time spent inside functions: the sum of the self times,
// which, unlike total times, do not overlap.
func functionTime(functions []FunctionCost) float64 {
	sum := 0.0
	for _, function := range functions {
		sum += function.Self
	}
	return sum
}

// calleeEpsilon absorbs the rounding of zprof's two-decimal output, so that a
// function without callees does not look like one.
const calleeEpsilon = 0.005

// hasCallees reports whether a function spent time in functions it called.
func hasCallees(self, total float64) bool {
	return total-self > calleeEpsilon
}

// callTrees returns the functions that call other functions, most total time
// first. Functions without callees are left out: their total equals their
// self time, which the self time ranking already shows.
func callTrees(functions []FunctionCost) []FunctionCost {
	var trees []FunctionCost
	for _, function := range functions {
		if hasCallees(function.Self, function.Total) {
			trees = append(trees, function)
		}
	}
	slices.SortStableFunc(trees, func(a, b FunctionCost) int {
		return cmp.Compare(b.Total, a.Total)
	})
	return trees
}

func computeStats(samples []float64) Stats {
	if len(samples) == 0 {
		return Stats{}
	}

	sorted := slices.Clone(samples)
	slices.Sort(sorted)

	sum := 0.0
	for _, sample := range samples {
		sum += sample
	}
	mean := sum / float64(len(samples))

	// Sample standard deviation; a single sample has no spread.
	stddev := 0.0
	if len(samples) > 1 {
		squares := 0.0
		for _, sample := range samples {
			squares += (sample - mean) * (sample - mean)
		}
		stddev = math.Sqrt(squares / float64(len(samples)-1))
	}

	middle := len(sorted) / 2
	median := sorted[middle]
	if len(sorted)%2 == 0 {
		median = (sorted[middle-1] + sorted[middle]) / 2
	}

	return Stats{
		Mean:    mean,
		Stddev:  stddev,
		Median:  median,
		Min:     sorted[0],
		Max:     sorted[len(sorted)-1],
		Samples: samples,
	}
}
