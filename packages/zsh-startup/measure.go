package main

import (
	"bytes"
	"context"
	"crypto/sha256"
	_ "embed"
	"encoding/hex"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/charmbracelet/x/ansi"
	"github.com/charmbracelet/x/term"
)

//go:embed scripts/prompt.zsh
var promptScript string

//go:embed scripts/state.zsh
var stateScript string

//go:embed scripts/zprof.zshenv
var zprofZshenv string

// zshTimeout stops a shell that hangs, for example on a startup file that
// waits for input.
const zshTimeout = 60 * time.Second

// keepTraceRows is how many files and lines a report keeps from the trace.
const keepTraceRows = 15

type measureOptions struct {
	zsh        string
	runs       int
	warmup     int
	promptRuns int
}

// progress prints one updating status line on stderr while a terminal shows it.
type progress struct {
	enabled bool
}

func newProgress() progress {
	return progress{enabled: term.IsTerminal(os.Stderr.Fd())}
}

func (p progress) show(format string, args ...any) {
	if !p.enabled {
		return
	}
	fmt.Fprintf(os.Stderr, "\r%s  measuring · %s", ansi.EraseEntireLine, fmt.Sprintf(format, args...))
}

func (p progress) clear() {
	if !p.enabled {
		return
	}
	fmt.Fprint(os.Stderr, "\r"+ansi.EraseEntireLine)
}

func measure(options measureOptions) (Report, error) {
	status := newProgress()
	defer status.clear()

	meta, err := collectMeta(options)
	if err != nil {
		return Report{}, err
	}

	startup, err := benchStartup(options, status)
	if err != nil {
		return Report{}, fmt.Errorf("startup: %w", err)
	}

	prompt, err := measurePrompt(options, status)
	if err != nil {
		return Report{}, fmt.Errorf("prompt: %w", err)
	}

	status.show("zprof")
	functions, profiledStartup, err := profileFunctions(options.zsh)
	if err != nil {
		return Report{}, fmt.Errorf("zprof: %w", err)
	}

	status.show("xtrace")
	trace, err := traceStartup(options.zsh)
	if err != nil {
		return Report{}, fmt.Errorf("xtrace: %w", err)
	}

	status.show("state")
	state, err := snapshotState(options.zsh)
	if err != nil {
		return Report{}, fmt.Errorf("state: %w", err)
	}

	return Report{
		Schema:          schemaVersion,
		Meta:            meta,
		Startup:         startup,
		Prompt:          prompt,
		Functions:       functions,
		ProfiledStartup: profiledStartup,
		Trace:           trace,
		State:           state,
	}, nil
}

// runZsh runs zsh with the given extra environment and arguments. Standard
// input is empty, so an interactive shell exits after its -c command.
func runZsh(zsh string, extraEnv []string, args ...string) (stdout, stderr string, err error) {
	ctx, cancel := context.WithTimeout(context.Background(), zshTimeout)
	defer cancel()

	var outBuffer, errBuffer bytes.Buffer
	command := exec.CommandContext(ctx, zsh, args...)
	command.Env = append(os.Environ(), extraEnv...)
	command.Stdout = &outBuffer
	command.Stderr = &errBuffer

	err = command.Run()
	if err != nil {
		return outBuffer.String(), errBuffer.String(), fmt.Errorf("%s %s: %w%s", zsh, strings.Join(args, " "), err, lastLines(errBuffer.String(), 5))
	}
	return outBuffer.String(), errBuffer.String(), nil
}

func lastLines(text string, count int) string {
	lines := strings.Split(strings.TrimRight(text, "\n"), "\n")
	if len(lines) == 1 && lines[0] == "" {
		return ""
	}
	start := max(0, len(lines)-count)
	return "\n  " + strings.Join(lines[start:], "\n  ")
}

func collectMeta(options measureOptions) (Meta, error) {
	version, _, err := runZsh(options.zsh, nil, "-f", "-c", "print -r -- $ZSH_VERSION")
	if err != nil {
		return Meta{}, err
	}

	host, err := os.Hostname()
	if err != nil {
		host = "unknown"
	}

	dir, err := os.Getwd()
	if err != nil {
		dir = ""
	}

	return Meta{
		Time:       time.Now(),
		Host:       host,
		Dir:        dir,
		ZshPath:    options.zsh,
		ZshVersion: strings.TrimSpace(version),
		Term:       os.Getenv("TERM"),
		Terminal:   hasControllingTerminal(),
		Config:     configHash(),
		Runs:       options.runs,
		Warmup:     options.warmup,
		PromptRuns: options.promptRuns,
	}, nil
}

// hasControllingTerminal reports whether the measured shells, which inherit
// this process's session, can open a controlling terminal.
func hasControllingTerminal() bool {
	tty, err := os.Open("/dev/tty")
	if err != nil {
		return false
	}
	tty.Close()
	return true
}

// configHash identifies the startup configuration by the contents of the
// user's .zshenv and .zshrc. Missing files are skipped.
func configHash() string {
	dotDir := os.Getenv("ZDOTDIR")
	if dotDir == "" {
		dotDir, _ = os.UserHomeDir()
	}

	hash := sha256.New()
	for _, name := range []string{".zshenv", ".zshrc"} {
		content, err := os.ReadFile(filepath.Join(dotDir, name))
		if err != nil {
			continue
		}
		hash.Write([]byte(name))
		hash.Write(content)
	}
	return hex.EncodeToString(hash.Sum(nil))[:8]
}

func benchStartup(options measureOptions, status progress) (Stats, error) {
	total := options.warmup + options.runs
	var samples []float64

	for i := range total {
		if i < options.warmup {
			status.show("startup warmup %d/%d", i+1, options.warmup)
		} else {
			status.show("startup %d/%d", i-options.warmup+1, options.runs)
		}

		start := time.Now()
		_, _, err := runZsh(options.zsh, nil, "-i", "-c", "exit")
		elapsed := time.Since(start)
		if err != nil {
			return Stats{}, err
		}

		if i >= options.warmup {
			samples = append(samples, float64(elapsed.Microseconds())/1000)
		}
	}
	return computeStats(samples), nil
}

// measurePrompt runs prompt.zsh in several shells and averages each hook.
func measurePrompt(options measureOptions, status progress) (PromptCost, error) {
	var order []string
	sums := map[string]float64{}
	var totals []float64

	for i := range options.promptRuns {
		status.show("first prompt %d/%d", i+1, options.promptRuns)

		stdout, _, err := runZsh(options.zsh, nil, "-i", "-c", promptScript)
		if err != nil {
			return PromptCost{}, err
		}

		total := 0.0
		for _, hook := range parsePromptRun(stdout) {
			if _, seen := sums[hook.Name]; !seen {
				order = append(order, hook.Name)
			}
			sums[hook.Name] += hook.Mean
			total += hook.Mean
		}
		totals = append(totals, total)
	}

	hooks := make([]HookCost, 0, len(order))
	for _, name := range order {
		hooks = append(hooks, HookCost{Name: name, Mean: sums[name] / float64(options.promptRuns)})
	}
	return PromptCost{Total: computeStats(totals), Hooks: hooks}, nil
}

// profileFunctions returns the zprof table and the wall time of the profiled
// shell, which includes the zprof overhead.
func profileFunctions(zsh string) ([]FunctionCost, float64, error) {
	dir, err := os.MkdirTemp("", "zsh-startup-")
	if err != nil {
		return nil, 0, err
	}
	defer os.RemoveAll(dir)

	err = os.WriteFile(filepath.Join(dir, ".zshenv"), []byte(zprofZshenv), 0o600)
	if err != nil {
		return nil, 0, err
	}

	env := []string{"ZDOTDIR=" + dir}
	if original, ok := os.LookupEnv("ZDOTDIR"); ok {
		env = append(env, "ZSH_STARTUP_ZDOTDIR="+original)
	}

	start := time.Now()
	stdout, _, err := runZsh(zsh, env, "-i", "-c", "zprof")
	wall := float64(time.Since(start).Microseconds()) / 1000
	if err != nil {
		return nil, 0, err
	}
	return parseZprof(stdout), wall, nil
}

func traceStartup(zsh string) (TraceSummary, error) {
	_, stderr, err := runZsh(zsh, []string{"PS4=" + tracePS4}, "-i", "-x", "-c", "exit")
	if err != nil {
		return TraceSummary{}, err
	}
	return parseTrace(stderr, keepTraceRows), nil
}

func snapshotState(zsh string) (State, error) {
	stdout, _, err := runZsh(zsh, nil, "-i", "-c", stateScript)
	if err != nil {
		return nil, err
	}
	return parseState(stdout), nil
}
