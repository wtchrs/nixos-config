// zsh-startup measures how long an interactive zsh takes to start and shows
// where the time goes. It saves each report as JSON so that a later run can
// compare against it.
package main

import (
	"errors"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/charmbracelet/colorprofile"
)

const usage = `Usage:
  zsh-startup [flags]                       measure and save a report
  zsh-startup compare [flags]               newest saved report vs a new measurement
  zsh-startup compare [flags] OLD.json      OLD vs a new measurement
  zsh-startup compare OLD.json NEW.json     two saved reports

Reports go to $XDG_CACHE_HOME/zsh-startup (default ~/.cache/zsh-startup)
unless --save names a file. With --json, stdout carries only JSON: a report
is the same document as its saved file. Flags come before file arguments.

Flags:
`

func main() {
	err := run(os.Args[1:])
	if errors.Is(err, flag.ErrHelp) {
		return
	}
	if err != nil {
		fmt.Fprintln(os.Stderr, "zsh-startup:", err)
		os.Exit(1)
	}
}

func run(args []string) error {
	if len(args) > 0 && args[0] == "compare" {
		return runCompare(args[1:])
	}
	return runReport(args)
}

type cliOptions struct {
	measure measureOptions
	save    string
	json    bool
}

func parseFlags(name string, args []string) (cliOptions, []string, error) {
	var options cliOptions

	flags := flag.NewFlagSet(name, flag.ContinueOnError)
	flags.Usage = func() {
		fmt.Fprint(flags.Output(), usage)
		flags.PrintDefaults()
	}
	flags.StringVar(&options.measure.zsh, "zsh", defaultZsh(), "zsh `binary` to measure")
	flags.IntVar(&options.measure.runs, "runs", 20, "measured startup runs")
	flags.IntVar(&options.measure.warmup, "warmup", 3, "startup runs to discard first")
	flags.IntVar(&options.measure.promptRuns, "prompt-runs", 5, "shells that time the first prompt")
	flags.StringVar(&options.save, "save", "", "write the new report to `file` instead of the cache directory")
	flags.BoolVar(&options.json, "json", false, "print JSON on stdout instead of the formatted output")

	err := flags.Parse(args)
	if err != nil {
		return cliOptions{}, nil, err
	}

	if options.measure.runs < 1 || options.measure.warmup < 0 || options.measure.promptRuns < 1 {
		return cliOptions{}, nil, errors.New("--runs and --prompt-runs must be at least 1, --warmup at least 0")
	}
	for _, arg := range flags.Args() {
		if strings.HasPrefix(arg, "-") {
			return cliOptions{}, nil, fmt.Errorf("flag %s after a file argument; put flags first", arg)
		}
	}
	return options, flags.Args(), nil
}

// defaultZsh prefers the login shell when it is zsh, so the tool measures the
// shell that terminals start.
func defaultZsh() string {
	shell := os.Getenv("SHELL")
	if filepath.Base(shell) == "zsh" {
		return shell
	}
	path, err := exec.LookPath("zsh")
	if err != nil {
		return "zsh"
	}
	return path
}

// output downsamples or strips colors to what stdout supports.
var output = colorprofile.NewWriter(os.Stdout, os.Environ())

// printJSON writes value to stdout. When a report was saved, the saved path
// goes to stderr so that stdout stays valid JSON.
func printJSON(value any, savedPath string) error {
	data, err := encodeJSON(value)
	if err != nil {
		return err
	}

	_, err = os.Stdout.Write(data)
	if err != nil {
		return err
	}

	if savedPath != "" {
		fmt.Fprintln(os.Stderr, "zsh-startup: saved", savedPath)
	}
	return nil
}

func runReport(args []string) error {
	options, files, err := parseFlags("zsh-startup", args)
	if err != nil {
		return err
	}
	if len(files) > 0 {
		return fmt.Errorf("unexpected argument %q; did you mean zsh-startup compare?", files[0])
	}

	report, err := measure(options.measure)
	if err != nil {
		return err
	}

	path, err := saveReport(report, options.save)
	if err != nil {
		return err
	}

	if options.json {
		return printJSON(report, path)
	}
	_, err = fmt.Fprint(output, renderReport(newRenderer(output.Profile), report, path))
	return err
}

func runCompare(args []string) error {
	options, files, err := parseFlags("zsh-startup compare", args)
	if err != nil {
		return err
	}
	if len(files) > 2 {
		return errors.New("compare takes at most two reports")
	}

	if len(files) == 2 {
		if options.save != "" {
			return errors.New("--save needs a new measurement; it does not apply to two saved reports")
		}
		return compareFiles(files[0], files[1], options.json)
	}

	// Pick the old report before measuring: the new report must not become
	// its own baseline.
	oldPath := ""
	if len(files) == 1 {
		oldPath = files[0]
	} else {
		dir, err := reportDir()
		if err != nil {
			return err
		}
		oldPath, err = latestReport(dir)
		if err != nil {
			return err
		}
	}

	old, err := loadReport(oldPath)
	if err != nil {
		return err
	}

	report, err := measure(options.measure)
	if err != nil {
		return err
	}

	newPath, err := saveReport(report, options.save)
	if err != nil {
		return err
	}

	comparison := compareReports(old, report, filepath.Base(oldPath), "measured now")
	if options.json {
		return printJSON(comparisonOutput(comparison, oldPath, newPath), newPath)
	}
	_, err = fmt.Fprint(output, renderComparison(newRenderer(output.Profile), comparison, newPath))
	return err
}

func compareFiles(oldPath, newPath string, asJSON bool) error {
	old, err := loadReport(oldPath)
	if err != nil {
		return err
	}
	new, err := loadReport(newPath)
	if err != nil {
		return err
	}

	comparison := compareReports(old, new, filepath.Base(oldPath), filepath.Base(newPath))
	if asJSON {
		return printJSON(comparisonOutput(comparison, oldPath, newPath), "")
	}
	_, err = fmt.Fprint(output, renderComparison(newRenderer(output.Profile), comparison, ""))
	return err
}
