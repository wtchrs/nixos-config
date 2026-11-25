package main

import (
	"image/color"

	"charm.land/lipgloss/v2"
)

// This file is the single source of truth for colors. The renderer refers
// only to the roles in theme, so a restyle changes this file and nothing else.

// nord is the Nord palette (https://www.nordtheme.com/docs/colors-and-palettes).
// Nord3Bright is the lighter comment color from the Nord editor themes; plain
// Nord3 is too dark for secondary text on a black terminal background.
var nord = struct {
	Nord0, Nord1, Nord2, Nord3, Nord3Bright color.Color
	Nord4, Nord5, Nord6                     color.Color
	Nord7, Nord8, Nord9, Nord10             color.Color
	Nord11, Nord12, Nord13, Nord14, Nord15  color.Color
}{
	Nord0:       lipgloss.Color("#2E3440"),
	Nord1:       lipgloss.Color("#3B4252"),
	Nord2:       lipgloss.Color("#434C5E"),
	Nord3:       lipgloss.Color("#4C566A"),
	Nord3Bright: lipgloss.Color("#616E88"),
	Nord4:       lipgloss.Color("#D8DEE9"),
	Nord5:       lipgloss.Color("#E5E9F0"),
	Nord6:       lipgloss.Color("#ECEFF4"),
	Nord7:       lipgloss.Color("#8FBCBB"),
	Nord8:       lipgloss.Color("#88C0D0"),
	Nord9:       lipgloss.Color("#81A1C1"),
	Nord10:      lipgloss.Color("#5E81AC"),
	Nord11:      lipgloss.Color("#BF616A"),
	Nord12:      lipgloss.Color("#D08770"),
	Nord13:      lipgloss.Color("#EBCB8B"),
	Nord14:      lipgloss.Color("#A3BE8C"),
	Nord15:      lipgloss.Color("#B48EAD"),
}

// theme maps each output role to a palette color.
var theme = struct {
	Accent   color.Color // section titles and the header border
	Heading  color.Color // the tool name in the header
	Emphasis color.Color // headline numbers
	Text     color.Color // regular values
	Label    color.Color // table headers and field names
	Muted    color.Color // secondary details and table rules
	Bar      color.Color // filled part of share bars
	BarTrack color.Color // empty part of share bars
	Better   color.Color // a change that makes startup faster
	Worse    color.Color // a change that makes startup slower
	Added    color.Color // state entries that appear in the new report
	Removed  color.Color // state entries that disappear in the new report
	Warning  color.Color // comparison caveats
}{
	Accent:   nord.Nord8,
	Heading:  nord.Nord6,
	Emphasis: nord.Nord6,
	Text:     nord.Nord4,
	Label:    nord.Nord9,
	Muted:    nord.Nord3Bright,
	Bar:      nord.Nord8,
	BarTrack: nord.Nord1,
	Better:   nord.Nord14,
	Worse:    nord.Nord11,
	Added:    nord.Nord14,
	Removed:  nord.Nord11,
	Warning:  nord.Nord13,
}
