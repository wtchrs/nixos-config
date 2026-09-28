package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"

	"tms/preview"
)

func (a *app) uniqueName(base string) string {
	name := base
	for suffix := 1; ; suffix++ {
		if _, err := a.mux("has-session", "-t", "="+name); err != nil {
			return name
		}
		name = fmt.Sprintf("%s-%d", base, suffix)
	}
}

func (a *app) connect(key string) bool {
	if !strings.HasPrefix(key, "s:") || !a.requireTarget(key) {
		return false
	}
	target := strings.TrimPrefix(key, "s:")
	if a.client != "" {
		_, err := a.mux("switch-client", "-c", a.client, "-t", target)
		return err == nil
	}
	return a.muxInteractive("attach-session", "-t", target) == nil
}

func (a *app) newSession(path string) bool {
	if info, err := os.Stat(path); err != nil || !info.IsDir() {
		a.notice("Directory does not exist: " + path)
		return false
	}
	name, ok := a.input("Session name> ", a.uniqueName(defaultSessionName(path)))
	if !ok || name == "" {
		return false
	}
	name = a.uniqueName(name)
	id, err := a.mux("new-session", "-d", "-P", "-F", "#{session_id}", "-s", name, "-c", path)
	if err != nil {
		a.notice(err.Error())
		return false
	}
	return a.connect("s:" + id)
}

func (a *app) renameTarget(key string) {
	if !strings.HasPrefix(key, "s:") {
		return
	}
	target := strings.TrimPrefix(key, "s:")
	name, err := a.mux("display-message", "-p", "-t", target, "#{session_name}")
	if err != nil {
		return
	}
	name, ok := a.input("New session name> ", name)
	if !ok || name == "" || !a.requireTarget(key) {
		return
	}
	if _, err := a.mux("rename-session", "-t", target, name); err != nil {
		a.notice(err.Error())
		return
	}
	a.refreshSnapshot()
}

func (a *app) deleteTarget(key string) {
	if !strings.HasPrefix(key, "s:") {
		return
	}
	target := strings.TrimPrefix(key, "s:")
	description, err := a.mux("display-message", "-p", "-t", target, "#{session_name}")
	if err != nil {
		return
	}
	current := ""
	if target == a.origin {
		current = " [current session]"
	}
	sessions, _ := a.mux("list-sessions", "-F", "#{session_id}")
	ids := strings.Fields(sessions)
	if len(ids) == 1 {
		current += " [last session: tmux will close]"
	}
	output, err := a.fzf([]string{"--no-sort", "--disabled", "--prompt", "Confirm> ",
		"--header", fmt.Sprintf("Delete session %s%s? Running processes may terminate.", description, current)},
		[]byte("Cancel\nDelete\n"))
	if err != nil || strings.TrimSuffix(string(output), "\n") != "Delete" || !a.requireTarget(key) {
		return
	}
	if target == a.origin && a.client != "" {
		for _, alternative := range ids {
			if alternative != target {
				if _, err := a.mux("switch-client", "-c", a.client, "-t", alternative); err != nil {
					return
				}
				break
			}
		}
	}
	if _, err := a.mux("kill-session", "-t", target); err != nil {
		a.notice(err.Error())
		return
	}
	a.refreshSnapshot()
}

func (a *app) picker(rows []string, position int) (query, key, selected string, ok bool) {
	header := "Enter: open  Ctrl-N/P or Ctrl-J/K: move\nCtrl-R: rename  Ctrl-X: delete  Ctrl-/: preview"
	if a.message != "" {
		header = a.message + "\n" + header
		a.message = ""
	}
	helper := shellQuote(a.self)
	args := []string{
		"--sync", "--layout=reverse", "--no-sort", "--highlight-line", "--ansi", "--cycle",
		"--delimiter=\t", "--with-nth=2..", "--id-nth=1", "--query", a.query,
		"--prompt", "tms> ", "--print-query", "--expect", "ctrl-r,ctrl-x",
		"--header", header,
		"--preview", helper + " --internal preview {1}",
		"--preview-window", "right,60%,<100(down,50%)",
		"--bind", fmt.Sprintf("start:pos(%d)", position),
		"--bind", "focus:execute-silent(" + helper + " --internal focus {1})",
		"--bind", "ctrl-n:down,ctrl-p:up,ctrl-j:down,ctrl-k:up,ctrl-/:toggle-preview,esc:transform:if test -n \"$FZF_QUERY\"; then echo clear-query; else echo abort; fi",
	}
	result, err := a.fzf(args, []byte(strings.Join(rows, "\n")+"\n"))
	if err != nil {
		return "", "", "", false
	}
	lines := strings.SplitN(string(result), "\n", 4)
	if len(lines) < 3 {
		return "", "", "", false
	}
	selected, _, _ = strings.Cut(lines[2], "\t")
	return lines[0], lines[1], selected, true
}

func (a *app) runPicker() {
	a.refreshSnapshot()
	_ = os.WriteFile(filepath.Join(a.state, "focus"), []byte("new"), 0600)
	for {
		rows := a.rows()
		focused, _ := os.ReadFile(filepath.Join(a.state, "focus"))
		position := 1
		for i, row := range rows {
			key, _, _ := strings.Cut(row, "\t")
			if key == string(focused) {
				position = i + 1
			}
		}
		query, key, selected, ok := a.picker(rows, position)
		if !ok {
			return
		}
		a.query = query
		if strings.HasPrefix(selected, "s:") && !a.requireTarget(selected) {
			continue
		}
		switch key {
		case "ctrl-r":
			a.renameTarget(selected)
			continue
		case "ctrl-x":
			a.deleteTarget(selected)
			continue
		}
		switch selected {
		case "new":
			if a.newSession(a.cwd) {
				return
			}
		case "other":
			if path, ok := a.chooseDirectory(); ok && a.newSession(path) {
				return
			}
		case "":
			continue
		default:
			if a.connect(selected) {
				return
			}
			a.requireTarget(selected)
		}
	}
}

func (a *app) internal(args []string) int {
	if len(args) == 0 {
		return 2
	}
	key := ""
	if len(args) > 1 {
		key = args[1]
	}
	switch args[0] {
	case "preview":
		switch key {
		case "new":
			fmt.Printf("Create a new session in:\n\n%s\n", a.cwd)
			return 0
		case "other":
			fmt.Println("Choose a directory, then create a new session there.")
			return 0
		}
		if !strings.HasPrefix(key, "s:") {
			return 0
		}
		preview.Render(strings.TrimPrefix(key, "s:"), os.Stdout)
		return 0
	case "focus":
		if a.state == "" {
			return 1
		}
		if err := os.WriteFile(filepath.Join(a.state, "focus"), []byte(key), 0600); err != nil {
			return 1
		}
		return 0
	case "directories":
		_, _ = os.Stdout.Write(a.directoryRows())
		return 0
	default:
		return 2
	}
}

func run(args []string) int {
	os.Setenv("FZF_DEFAULT_OPTS", "--layout=reverse")
	os.Setenv("FZF_DEFAULT_OPTS_FILE", "")
	os.Setenv("FZF_DEFAULT_COMMAND", "")
	self, err := os.Executable()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		return 1
	}
	self, err = filepath.EvalSymlinks(self)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		return 1
	}
	if filepath.Base(self) == ".tms-wrapped" {
		self = filepath.Join(filepath.Dir(self), "tms")
	}
	cwd, err := os.Getwd()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		return 1
	}
	a := &app{self: self, cwd: cwd, client: os.Getenv("TMS_CLIENT"), origin: os.Getenv("TMS_ORIGIN_SESSION"), state: os.Getenv("TMS_STATE")}
	if value := os.Getenv("TMS_CWD"); value != "" {
		a.cwd = value
	}
	if len(args) > 0 && args[0] == "--internal" {
		return a.internal(args[1:])
	}

	socketName, socketPath, inline := "", "", false
	for len(args) > 0 {
		arg := args[0]
		args = args[1:]
		switch arg {
		case "-L", "-S":
			if len(args) == 0 {
				fmt.Fprintln(os.Stderr, "Missing socket argument")
				return 2
			}
			if arg == "-L" {
				socketName = args[0]
			} else {
				socketPath = args[0]
			}
			args = args[1:]
		case "--inline":
			inline = true
		case "-h", "--help":
			fmt.Println("Usage: tms [-L socket-name | -S socket-path]")
			return 0
		default:
			fmt.Fprintln(os.Stderr, "Unknown option:", arg)
			return 2
		}
	}
	if _, err := exec.LookPath("tmux"); err != nil {
		fmt.Fprintln(os.Stderr, "tms requires tmux and fzf.")
		return 127
	}
	if _, err := exec.LookPath("fzf"); err != nil {
		fmt.Fprintln(os.Stderr, "tms requires tmux and fzf.")
		return 127
	}
	version, err := commandOutput("fzf", "--version")
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		return 1
	}
	versionFields := strings.Fields(version)
	if len(versionFields) == 0 {
		fmt.Fprintln(os.Stderr, "Unable to read fzf version.")
		return 1
	}
	version = versionFields[0]
	parts := strings.Split(version, ".")
	major, minor := 0, 0
	if len(parts) > 0 {
		major, _ = strconv.Atoi(parts[0])
	}
	if len(parts) > 1 {
		minor, _ = strconv.Atoi(parts[1])
	}
	if major == 0 && minor < 74 {
		fmt.Fprintln(os.Stderr, "tms requires fzf 0.74 or newer.")
		return 1
	}

	inheritedTMUX := os.Getenv("TMUX")
	a.socket = socketPath
	if a.socket == "" {
		a.socket, _, _ = strings.Cut(inheritedTMUX, ",")
	}
	if socketName != "" && socketPath == "" {
		root := os.Getenv("TMUX_TMPDIR")
		if root == "" {
			root = "/tmp"
		}
		a.socket = filepath.Join(root, fmt.Sprintf("tmux-%d", os.Getuid()), socketName)
	}
	os.Setenv("TMS_SOCKET", a.socket)
	if inheritedTMUX != "" && !inline {
		client, err := commandOutput("tmux", "display-message", "-p", "#{client_name}")
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			return 1
		}
		a.client = client
		a.origin, err = commandOutput("tmux", "display-message", "-p", "#{session_id}")
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			return 1
		}
		a.cwd, err = commandOutput("tmux", "display-message", "-p", "#{pane_current_path}")
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			return 1
		}
		originalSocket, _, _ := strings.Cut(inheritedTMUX, ",")
		if a.socket != originalSocket {
			fmt.Fprintln(os.Stderr, "Open another server with tms from outside tmux.")
			return 2
		}
		command := shellQuote(a.self) + " --inline"
		_, err = a.mux("display-popup", "-d", a.cwd, "-w90%", "-h80%", "-E",
			"-e", "TMS_CLIENT="+a.client, "-e", "TMS_ORIGIN_SESSION="+a.origin,
			"-e", "TMS_CWD="+a.cwd, "-e", "TMS_SOCKET="+a.socket, command)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			return 1
		}
		return 0
	}
	physical, err := filepath.EvalSymlinks(a.cwd)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		return 1
	}
	a.cwd, err = filepath.Abs(physical)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		return 1
	}
	os.Setenv("TMS_CWD", a.cwd)
	root := os.Getenv("TMPDIR")
	if root == "" {
		root = os.TempDir()
	}
	a.state, err = os.MkdirTemp(root, "tms.")
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		return 1
	}
	defer os.RemoveAll(a.state)
	os.Setenv("TMS_STATE", a.state)
	os.Setenv("TMS_CLIENT", a.client)
	os.Setenv("TMS_ORIGIN_SESSION", a.origin)
	a.runPicker()
	return 0
}

func main() {
	os.Exit(run(os.Args[1:]))
}
