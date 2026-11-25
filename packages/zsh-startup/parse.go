package main

import (
	"bufio"
	"cmp"
	"regexp"
	"slices"
	"strconv"
	"strings"
)

// zprofRow matches one row of the first zprof table:
//
//	num  calls   total ms  per call  share   self ms  per call  share   name
//	 1)    4      64.69     16.17   45.89%    64.69     16.17   45.89%  compaudit
var zprofRow = regexp.MustCompile(
	`^\s*\d+\)\s+(\d+)\s+([\d.]+)\s+[\d.]+\s+[\d.]+%\s+([\d.]+)\s+[\d.]+\s+[\d.]+%\s+(.+?)\s*$`,
)

// parseZprof reads the first zprof table. zprof prints a call graph after
// that table; the graph starts after the first blank line.
func parseZprof(output string) []FunctionCost {
	var functions []FunctionCost
	seenTable := false

	scanner := bufio.NewScanner(strings.NewReader(output))
	for scanner.Scan() {
		line := scanner.Text()

		match := zprofRow.FindStringSubmatch(line)
		if match == nil {
			if seenTable && strings.TrimSpace(line) == "" {
				break
			}
			continue
		}
		seenTable = true

		calls, _ := strconv.Atoi(match[1])
		total, _ := strconv.ParseFloat(match[2], 64)
		self, _ := strconv.ParseFloat(match[3], 64)
		functions = append(functions, FunctionCost{
			Name:  match[4],
			Calls: calls,
			Total: total,
			Self:  self,
		})
	}

	slices.SortStableFunc(functions, func(a, b FunctionCost) int {
		return cmp.Compare(b.Self, a.Self)
	})
	return functions
}

// traceSeparator splits the fields of the PS4 prefix. It is a control
// character so that it cannot appear in file names or traced commands.
const traceSeparator = "\x1f"

// tracePS4 makes every xtrace line start with
// "+<epoch seconds>.<microseconds> US <file> US <line> US <command>".
// %x is the file that contains the code, also inside functions.
const tracePS4 = "+%D{%s.%6.}" + traceSeparator + "%x" + traceSeparator + "%I" + traceSeparator

// maxCommandLength caps the traced command text that a report keeps. Some
// traced lines expand to hundreds of kilobytes, such as compaudit's list of
// every completion file, and the output shows only the start anyway.
const maxCommandLength = 200

// shortenCommand keeps the first maxCommandLength runes of a command.
func shortenCommand(command string) string {
	runes := []rune(command)
	if len(runes) <= maxCommandLength {
		return command
	}
	return string(runes[:maxCommandLength]) + "…"
}

type traceEntry struct {
	at      float64 // seconds since the epoch
	path    string
	line    int
	command string
}

// parseTrace reads xtrace output written with tracePS4. Each entry is charged
// with the time until the next entry starts. Lines that do not start with the
// PS4 prefix, such as the rest of a multi-line command, are skipped.
func parseTrace(output string, keep int) TraceSummary {
	var entries []traceEntry

	scanner := bufio.NewScanner(strings.NewReader(output))
	scanner.Buffer(make([]byte, 0, 64*1024), 16*1024*1024)
	for scanner.Scan() {
		entry, ok := parseTraceLine(scanner.Text())
		if ok {
			entries = append(entries, entry)
		}
	}

	if len(entries) < 2 {
		return TraceSummary{Lines: len(entries)}
	}

	timeByPath := map[string]float64{}
	linesByPath := map[string]int{}
	var lineCosts []LineCost

	for i := 0; i < len(entries)-1; i++ {
		entry := entries[i]
		elapsed := (entries[i+1].at - entry.at) * 1000

		timeByPath[entry.path] += elapsed
		linesByPath[entry.path]++
		lineCosts = append(lineCosts, LineCost{
			Path:    entry.path,
			Line:    entry.line,
			Command: shortenCommand(entry.command),
			Time:    elapsed,
		})
	}

	var files []FileCost
	for path, elapsed := range timeByPath {
		files = append(files, FileCost{Path: path, Time: elapsed, Lines: linesByPath[path]})
	}
	slices.SortFunc(files, func(a, b FileCost) int {
		return cmp.Or(cmp.Compare(b.Time, a.Time), cmp.Compare(a.Path, b.Path))
	})

	slices.SortStableFunc(lineCosts, func(a, b LineCost) int {
		return cmp.Compare(b.Time, a.Time)
	})

	first := entries[0].at
	last := entries[len(entries)-1].at
	return TraceSummary{
		Total:   (last - first) * 1000,
		Lines:   len(entries),
		Files:   files[:min(keep, len(files))],
		Slowest: lineCosts[:min(keep, len(lineCosts))],
	}
}

func parseTraceLine(line string) (traceEntry, bool) {
	if !strings.HasPrefix(line, "+") {
		return traceEntry{}, false
	}

	fields := strings.SplitN(line[1:], traceSeparator, 4)
	if len(fields) != 4 {
		return traceEntry{}, false
	}

	at, err := strconv.ParseFloat(fields[0], 64)
	if err != nil {
		return traceEntry{}, false
	}
	lineNumber, _ := strconv.Atoi(fields[2])

	return traceEntry{
		at:      at,
		path:    fields[1],
		line:    lineNumber,
		command: fields[3],
	}, true
}

// sectionMarker starts a section in the output of state.zsh and prompt.zsh.
const sectionMarker = "@@"

// parseState reads the output of state.zsh: a "@@<category>" line followed by
// the output of the command that lists that category.
func parseState(output string) State {
	state := State{}
	for _, category := range stateCategories {
		state[category] = map[string]string{}
	}

	current := ""
	scanner := bufio.NewScanner(strings.NewReader(output))
	for scanner.Scan() {
		line := scanner.Text()

		if category, ok := strings.CutPrefix(line, sectionMarker); ok {
			current = category
			continue
		}
		entries, known := state[current]
		if !known || line == "" {
			continue
		}

		key, value := stateEntry(current, line)
		entries[key] = value
	}
	return state
}

// stateEntry splits one listed line into a key and a value, so that compare
// can tell a changed entry from an added or removed one.
func stateEntry(category, line string) (string, string) {
	switch category {
	case "aliases":
		// alias prints name=value.
		name, value, _ := strings.Cut(line, "=")
		return name, value
	case "bindkeys":
		// bindkey -L prints the binding command; its last word is the widget.
		binding := strings.TrimPrefix(line, "bindkey ")
		index := strings.LastIndex(binding, " ")
		if index < 0 {
			return binding, ""
		}
		return binding[:index], binding[index+1:]
	case "zstyles":
		// state.zsh prints "<pattern> <style>\t<values>".
		key, value, _ := strings.Cut(line, "\t")
		return key, value
	default:
		// setopt prints the names of the options that differ from the defaults.
		return line, ""
	}
}

// parsePromptRun reads one run of prompt.zsh: "@@<name>\t<milliseconds>" lines
// in execution order.
func parsePromptRun(output string) []HookCost {
	var hooks []HookCost

	scanner := bufio.NewScanner(strings.NewReader(output))
	for scanner.Scan() {
		rest, ok := strings.CutPrefix(scanner.Text(), sectionMarker)
		if !ok {
			continue
		}

		name, value, found := strings.Cut(rest, "\t")
		if !found {
			continue
		}
		elapsed, err := strconv.ParseFloat(strings.TrimSpace(value), 64)
		if err != nil {
			continue
		}
		hooks = append(hooks, HookCost{Name: name, Mean: elapsed})
	}
	return hooks
}
