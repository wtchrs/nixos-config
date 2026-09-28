package main

import (
	"bytes"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"unicode"
)

type session struct {
	id, name, path, command, windows, attached string
	lastAttached                               int64
}

type app struct {
	self, socket, cwd, client, origin, state string
	query, message                           string
	snapshot                                 []session
	snapshotReady                            bool
	order                                    []string
	gitCache                                 map[string]string
}

func shellQuote(value string) string {
	return "'" + strings.ReplaceAll(value, "'", "'\\''") + "'"
}

func clean(value string) string {
	return strings.Map(func(r rune) rune {
		if r == '\t' || r == '\n' || r == '\r' || r == '\x1b' {
			return ' '
		}
		return r
	}, value)
}

func commandOutput(name string, args ...string) (string, error) {
	cmd := exec.Command(name, args...)
	var stdout, stderr bytes.Buffer
	cmd.Stdout, cmd.Stderr = &stdout, &stderr
	if err := cmd.Run(); err != nil {
		message := strings.TrimSpace(stderr.String())
		if message == "" {
			message = err.Error()
		}
		return "", errors.New(message)
	}
	return strings.TrimSuffix(stdout.String(), "\n"), nil
}

func (a *app) muxArgs(args ...string) []string {
	if a.socket == "" {
		return args
	}
	return append([]string{"-S", a.socket}, args...)
}

func (a *app) mux(args ...string) (string, error) {
	return commandOutput("tmux", a.muxArgs(args...)...)
}

func (a *app) muxInteractive(args ...string) error {
	cmd := exec.Command("tmux", a.muxArgs(args...)...)
	cmd.Stdin, cmd.Stdout, cmd.Stderr = os.Stdin, os.Stdout, os.Stderr
	return cmd.Run()
}

func (a *app) fzf(args []string, input []byte) ([]byte, error) {
	cmd := exec.Command("fzf", args...)
	cmd.Stdin = bytes.NewReader(input)
	cmd.Stderr = os.Stderr
	var output bytes.Buffer
	cmd.Stdout = &output
	err := cmd.Run()
	return output.Bytes(), err
}

func (a *app) gitInfo(path string) string {
	if branch, ok := a.gitCache[path]; ok {
		return branch
	}
	branch, err := commandOutput("git", "-C", path, "symbolic-ref", "--quiet", "--short", "HEAD")
	if err != nil {
		branch, err = commandOutput("git", "-C", path, "rev-parse", "--short", "HEAD")
	}
	if err == nil {
		actual, _ := commandOutput("git", "-C", path, "rev-parse", "--absolute-git-dir")
		common, _ := commandOutput("git", "-C", path, "rev-parse", "--path-format=absolute", "--git-common-dir")
		if actual != common {
			branch += " [worktree]"
		}
	} else {
		branch = ""
	}
	a.gitCache[path] = clean(branch)
	return a.gitCache[path]
}

func (a *app) refreshSnapshot() {
	const format = "#{session_id}\t#{?session_last_attached,#{session_last_attached},0}\t#{session_name}\t#{session_path}\t#{pane_current_command}\t#{session_windows}\t#{session_attached}"
	output, err := a.mux("list-sessions", "-F", format)
	a.snapshot = nil
	a.snapshotReady = true
	a.gitCache = make(map[string]string)
	if err != nil {
		return
	}
	for _, line := range strings.Split(output, "\n") {
		fields := strings.SplitN(line, "\t", 7)
		if len(fields) != 7 || fields[0] == "" {
			continue
		}
		stamp, _ := strconv.ParseInt(fields[1], 10, 64)
		a.snapshot = append(a.snapshot, session{
			id: fields[0], lastAttached: stamp, name: fields[2], path: fields[3],
			command: fields[4], windows: fields[5], attached: fields[6],
		})
	}
	sort.SliceStable(a.snapshot, func(i, j int) bool {
		return a.snapshot[i].lastAttached > a.snapshot[j].lastAttached
	})
	known := make(map[string]bool, len(a.order))
	for _, id := range a.order {
		known[id] = true
	}
	for _, s := range a.snapshot {
		if !known[s.id] {
			a.order = append(a.order, s.id)
			known[s.id] = true
		}
	}
}

func (a *app) rows() []string {
	if !a.snapshotReady {
		a.refreshSnapshot()
	}
	rows := []string{"new\t+ New session", "other\t+ New session in other directory"}
	live := make(map[string]session, len(a.snapshot))
	for _, s := range a.snapshot {
		live[s.id] = s
	}
	for _, id := range a.order {
		s, ok := live[id]
		if !ok {
			continue
		}
		label := "  " + clean(s.name)
		if id == a.origin && a.origin != "" {
			label = "\x1b[1;36m● " + clean(s.name) + " (current)\x1b[0m"
		}
		unit := "windows"
		if s.windows == "1" {
			unit = "window"
		}
		label += " · " + s.windows + " " + unit
		if s.attached != "0" {
			label += " (attached)"
		}
		rows = append(rows, fmt.Sprintf("s:%s\t%s  %s  %s  %s", id, label,
			clean(s.path), clean(s.command), a.gitInfo(s.path)))
	}
	return rows
}

func (a *app) targetExists(key string) bool {
	if !strings.HasPrefix(key, "s:") || len(key) == 2 {
		return false
	}
	_, err := a.mux("has-session", "-t", strings.TrimPrefix(key, "s:"))
	return err == nil
}

func (a *app) requireTarget(key string) bool {
	if a.targetExists(key) {
		return true
	}
	a.refreshSnapshot()
	a.message = "Selected item no longer exists. List refreshed; choose again."
	return false
}

func (a *app) input(prompt, initial string) (string, bool) {
	output, err := a.fzf([]string{
		"--disabled", "--print-query", "--query", initial, "--prompt", prompt,
		"--header", "Enter: confirm  Esc: cancel", "--bind", "enter:print-query",
	}, nil)
	return strings.TrimSuffix(string(output), "\n"), err == nil
}

func (a *app) notice(message string) {
	_, _ = a.fzf([]string{"--disabled", "--prompt", "Continue> ",
		"--header", "Enter or Esc: return"}, []byte(message+"\n"))
}

func (a *app) directoryRows() []byte {
	seen := make(map[string]bool)
	var rows bytes.Buffer
	add := func(path string) {
		if path == "" || seen[path] {
			return
		}
		if info, err := os.Stat(path); err != nil || !info.IsDir() {
			return
		}
		seen[path] = true
		rows.WriteString(path)
		rows.WriteByte(0)
	}
	if _, err := exec.LookPath("zoxide"); err == nil {
		if output, err := commandOutput("zoxide", "query", "--list"); err == nil {
			for _, path := range strings.Split(output, "\n") {
				add(path)
			}
		}
	}
	if terminal, err := os.Open("/dev/tty"); err == nil {
		defer terminal.Close()
		cmd := exec.Command("fzf", "--walker=dir,hidden", "--walker-skip=.git",
			"--walker-root", a.cwd, "--filter", "", "--print0")
		cmd.Stdin = terminal
		if output, err := cmd.Output(); err == nil {
			for _, path := range bytes.Split(output, []byte{0}) {
				add(string(path))
			}
		}
	}
	return rows.Bytes()
}

func (a *app) chooseDirectory() (string, bool) {
	output, err := a.fzf([]string{
		"--read0", "--print0", "--no-sort", "--scheme=path", "--filepath-word",
		"--prompt", "Directory> ",
		"--header", "Enter: choose  Ctrl-L: enter path  Ctrl-S: sort  Esc: cancel",
		"--bind", "ctrl-s:toggle-sort", "--expect", "ctrl-l",
	}, a.directoryRows())
	if err != nil {
		return "", false
	}
	fields := bytes.Split(output, []byte{0})
	if len(fields) < 2 {
		return "", false
	}
	key, path := string(fields[0]), string(fields[1])
	if key == "ctrl-l" {
		for {
			if path == "" {
				path = a.cwd + "/"
			}
			entered, ok := a.input("Directory path> ", path)
			if !ok {
				return "", false
			}
			path = entered
			if path == "~" {
				path = os.Getenv("HOME")
			} else if strings.HasPrefix(path, "~/") {
				path = filepath.Join(os.Getenv("HOME"), path[2:])
			}
			if !filepath.IsAbs(path) {
				path = filepath.Join(a.cwd, path)
			}
			if info, err := os.Stat(path); err == nil && info.IsDir() {
				break
			}
			a.notice("Directory does not exist: " + path)
		}
	}
	if info, err := os.Stat(path); err != nil || !info.IsDir() {
		a.notice("The selected directory no longer exists.")
		return "", false
	}
	physical, err := filepath.EvalSymlinks(path)
	if err != nil {
		return "", false
	}
	physical, err = filepath.Abs(physical)
	return physical, err == nil
}

func defaultSessionName(path string) string {
	base := filepath.Base(path)
	if path == string(filepath.Separator) {
		base = ""
	}
	var result strings.Builder
	for _, r := range base {
		if unicode.IsLetter(r) || unicode.IsNumber(r) || r == '_' || r == '-' {
			result.WriteRune(r)
		} else {
			result.WriteByte('_')
		}
	}
	if result.Len() == 0 {
		return "root"
	}
	return result.String()
}
