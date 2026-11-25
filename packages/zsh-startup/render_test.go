package main

import (
	"strings"
	"testing"

	"charm.land/lipgloss/v2"
	"github.com/charmbracelet/x/ansi"
)

func TestShortPath(t *testing.T) {
	t.Setenv("HOME", "/home/user")

	cases := map[string]string{
		"/nix/store/3mv4pyfx9425z8pp9mdmljhk5nj18kjg-ls_colors.sh":                               "ls_colors.sh",
		"/nix/store/l9j8gsbwxjc5vzr4dlm5frqsdcw41968-br.zsh/br":                                  "br.zsh/br",
		"/nix/store/ygl65lvv7lh5hmkr06snx80dkz6k9y98-oh-my-zsh-2026-11-02/share/oh-my-zsh/x.zsh": "oh-my-zsh-2026-11-02/…/x.zsh",
		"/etc/profiles/per-user/user/share/zsh/5.9.2/functions/compinit":                         "zsh/functions/compinit",
		"/home/user/.zshrc": "~/.zshrc",
		"/home/user":        "~",
		"/etc/zshrc":        "/etc/zshrc",
	}
	for path, want := range cases {
		if got := shortPath(path); got != want {
			t.Errorf("shortPath(%q) = %q, want %q", path, got, want)
		}
	}
}

func TestShortTextDropsStoreHashes(t *testing.T) {
	command := "/nix/store/k823pfzjx1l37gd2s4bxvchqlmfadah6-rgrc-0.6.35/bin/rgrc --aliases --except ls"
	if got := shortText(command); got != "rgrc --aliases --except ls" {
		t.Errorf("shortText = %q", got)
	}

	sourced := "source /nix/store/zbrh3inpr0k7dzgmwg7fagp5n62vghz1-zsh-fzf-tab-1.3.0/share/fzf-tab/fzf-tab.plugin.zsh"
	if got := shortText(sourced); got != "source zsh-fzf-tab-1.3.0/share/fzf-tab/fzf-tab.plugin.zsh" {
		t.Errorf("shortText = %q", got)
	}
}

func TestDisplayFunctionShortensAnonymousFunctions(t *testing.T) {
	name := "(anon) [/nix/store/ygl65lvv7lh5hmkr06snx80dkz6k9y98-oh-my-zsh-2026-11-02/share/oh-my-zsh/oh-my-zsh.sh:210]"
	if got := displayFunction(name); got != "(anon) oh-my-zsh-2026-11-02/…/oh-my-zsh.sh:210" {
		t.Errorf("displayFunction = %q", got)
	}
}

func TestCutKeepsTheRequestedWidth(t *testing.T) {
	text := "/etc/profiles/per-user/user/share/zsh"

	left := cut(text, 12, true)
	if lipgloss.Width(left) != 12 || left[len(left)-3:] != "zsh" {
		t.Errorf("cut from left = %q (width %d)", left, lipgloss.Width(left))
	}

	right := cut(text, 12, false)
	if lipgloss.Width(right) != 12 || right[:4] != "/etc" {
		t.Errorf("cut from right = %q (width %d)", right, lipgloss.Width(right))
	}
}

func TestBarWithoutColorsShowsTheTrack(t *testing.T) {
	r := renderer{noColor: true, width: 100}
	got := ansi.Strip(r.bar(0.5))

	want := strings.Repeat("█", barWidth/2) + strings.Repeat("░", barWidth/2) + " 50%"
	if got != want {
		t.Errorf("bar(0.5) = %q, want %q", got, want)
	}
}

func TestBarHasAFixedWidth(t *testing.T) {
	for _, plain := range []bool{true, false} {
		r := renderer{plain: plain, width: 100}
		for _, share := range []float64{0, 0.004, 0.33, 0.5, 1, 1.5} {
			got := lipgloss.Width(r.bar(share))
			label := lipgloss.Width(" " + formatShare(min(share, 1)))
			if got != barWidth+label {
				t.Errorf("plain=%v share=%v: width %d, want %d", plain, share, got, barWidth+label)
			}
		}
	}
}
