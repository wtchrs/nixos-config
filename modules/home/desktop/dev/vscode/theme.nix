{ pkgs, ... }:

let
  nord = rec {
    transparent = "#00000000";

    # -- Nord base palette
    # Keep the full palette, including colors not currently referenced.

    nord0 = "#2e3440";
    nord1 = "#3b4252";
    nord2 = "#434c5e";
    nord3 = "#4c566a";
    nord3Bright = "#616e88";

    nord4 = "#d8dee9";
    nord5 = "#e5e9f0";
    nord6 = "#eceff4";

    nord7 = "#8fbcbb";
    nord8 = "#88c0d0";
    nord9 = "#81a1c1";
    nord10 = "#5e81ac";

    nord11 = "#bf616a";
    nord12 = "#d08770";
    nord13 = "#ebcb8b";
    nord14 = "#a3be8c";
    nord15 = "#b48ead";

    # -- Foreground variants

    foregroundPrimary = nord4;
    foregroundSecondary = nord5;
    foregroundBright = nord6;

    foregroundSubtle = "#d8dee966";
    foregroundDim = "#d8dee980";
    foregroundMuted = "#d8dee999";
    foregroundStrong = "#d8dee9CC";

    # -- Neutral surface variants

    surfaceLine = "#3b42524D";
    surfaceWeak = "#3b425266";
    surfaceHover = "#3b425280";
    surfaceMedium = "#3b425299";
    surfaceStrong = "#3b4252CC";

    surfaceAltWeak = "#434c5e66";
    surfaceAltHover = "#434c5e80";
    surfaceAltMedium = "#434c5e99";
    surfaceAltStrong = "#434c5eCC";

    surfacePressed = "#4c566a99";
    surfacePressedStrong = "#4c566aCC";

    whitespace = "#4c566a80";
    border = "#3b425280";

    # -- Accent variants

    accentVeryWeak = "#88c0d022";
    accentWeak = "#88c0d033";
    accentSelection = "#88c0d055";
    accentBorder = "#88c0d080";
    accentStrong = "#88c0d099";
    accentButton = "#88c0d0E6";

    accentSelectionTerminal = "#88c0d04D";
    accentAltButton = "#8fbcbbE6";

    # -- Status variants

    debugBackground = "#5e81acCC";

    diffAddedText = "#a3be8c26";
    diffAddedLine = "#a3be8c14";

    diffRemovedText = "#bf616a26";
    diffRemovedLine = "#bf616a14";
  };

in
{
  programs.vscode.profiles.default = {
    extensions = with pkgs.vscode-extensions; [
      arcticicestudio.nord-visual-studio-code
    ];

    userSettings = {
      "workbench.experimental.modernUI" = true;

      # -- Nord theme

      "workbench.colorTheme" = "Nord";
      "workbench.preferredDarkColorTheme" = "Nord";
      "window.autoDetectColorScheme" = false;

      # Keep Nord semantic highlighting.
      "editor.semanticHighlighting.enabled" = true;

      # Ghostty configuration disables ligatures.
      "editor.fontLigatures" = false;

      # Preserve the theme's ANSI colors instead of increasing contrast.
      "terminal.integrated.minimumContrastRatio" = 1;
      "terminal.integrated.fontFamily" = "'Sarasa Mono K', monospace";
      "terminal.integrated.fontSize" = 14;
      "terminal.integrated.stickyScroll.enabled" = false;

      "workbench.colorCustomizations" = {
        "[Nord]" = {
          # -- Focus

          "focusBorder" = nord.nord8;
          "contrastActiveBorder" = nord.transparent;
          "contrastBorder" = nord.transparent;

          # -- Inputs

          "input.foreground" = nord.foregroundBright;
          "input.placeholderForeground" = nord.foregroundSubtle;
          "input.border" = nord.border;

          "quickInputList.focusBackground" = nord.surfaceStrong;
          "quickInputList.focusForeground" = nord.foregroundBright;

          # -- Editor

          "editorLineNumber.activeForeground" = nord.foregroundBright;

          "editorWhitespace.foreground" = nord.whitespace;

          "editorIndentGuide.background1" = nord.surfaceWeak;
          "editorIndentGuide.activeBackground1" = nord.accentStrong;

          "editor.lineHighlightBackground" = nord.surfaceLine;
          "editor.lineHighlightBorder" = nord.transparent;

          "editor.selectionBackground" = nord.accentSelection;
          "editor.inactiveSelectionBackground" = nord.accentWeak;
          "editor.selectionHighlightBackground" = nord.accentVeryWeak;

          "editorBracketMatch.background" = nord.accentWeak;

          # -- Bracket pair colorization

          "editorBracketHighlight.foreground1" = nord.nord8;
          "editorBracketHighlight.foreground2" = nord.nord15;
          "editorBracketHighlight.foreground3" = nord.nord13;
          "editorBracketHighlight.foreground4" = nord.nord14;
          "editorBracketHighlight.foreground5" = nord.nord9;
          "editorBracketHighlight.foreground6" = nord.nord12;

          # -- Tabs / editor groups

          "editorGroup.border" = nord.border;

          "tab.activeBackground" = nord.surfaceWeak;
          "tab.hoverBackground" = nord.surfaceLine;

          "tab.activeForeground" = nord.foregroundBright;
          "tab.inactiveForeground" = nord.foregroundMuted;
          "tab.unfocusedActiveForeground" = nord.foregroundStrong;

          "tab.activeBorder" = nord.transparent;
          "tab.activeBorderTop" = nord.nord8;
          "tab.unfocusedActiveBorderTop" = nord.accentBorder;

          # -- Sidebar / lists

          "sideBar.border" = nord.border;

          "sideBarTitle.foreground" = nord.foregroundBright;

          "sideBarSectionHeader.foreground" = nord.foregroundSecondary;
          "sideBarSectionHeader.border" = nord.border;

          "list.activeSelectionBackground" = nord.surfaceStrong;
          "list.activeSelectionForeground" = nord.foregroundBright;

          "list.inactiveSelectionBackground" = nord.surfaceMedium;
          "list.inactiveSelectionForeground" = nord.foregroundSecondary;

          "list.hoverBackground" = nord.surfaceHover;

          "list.focusBackground" = nord.surfaceAltStrong;
          "list.focusForeground" = nord.foregroundBright;

          # -- Activity bar

          "activityBar.inactiveForeground" = nord.foregroundSubtle;

          "activityBar.border" = nord.transparent;

          # -- Panel / status bar

          "panel.border" = nord.border;

          "panelTitle.activeBorder" = nord.nord8;
          "panelTitle.inactiveForeground" = nord.foregroundDim;

          "statusBar.border" = nord.transparent;

          "statusBar.debuggingBackground" = nord.debugBackground;
          "statusBar.debuggingForeground" = nord.foregroundBright;

          "statusBarItem.hoverBackground" = nord.surfaceAltMedium;
          "statusBarItem.activeBackground" = nord.surfacePressed;

          "statusBarItem.prominentBackground" = nord.surfaceMedium;
          "statusBarItem.prominentHoverBackground" = nord.surfaceAltStrong;

          # -- Buttons

          "button.background" = nord.accentButton;
          "button.hoverBackground" = nord.accentAltButton;

          "button.secondaryBackground" = nord.surfaceAltStrong;
          "button.secondaryForeground" = nord.foregroundSecondary;
          "button.secondaryHoverBackground" = nord.surfacePressedStrong;

          # -- Scrollbars

          "scrollbarSlider.background" = nord.surfaceAltWeak;
          "scrollbarSlider.hoverBackground" = nord.surfacePressed;
          "scrollbarSlider.activeBackground" = nord.accentStrong;

          # -- Diagnostics

          "editorInfo.foreground" = nord.nord8;
          "editorHint.foreground" = nord.nord7;

          "problemsErrorIcon.foreground" = nord.nord11;
          "problemsWarningIcon.foreground" = nord.nord13;
          "problemsInfoIcon.foreground" = nord.nord8;

          # -- Git

          "gitDecoration.addedResourceForeground" = nord.nord14;
          "gitDecoration.renamedResourceForeground" = nord.nord8;
          "gitDecoration.untrackedResourceForeground" = nord.nord7;
          "gitDecoration.ignoredResourceForeground" = nord.nord3;
          "gitDecoration.conflictingResourceForeground" = nord.nord12;
          "gitDecoration.submoduleResourceForeground" = nord.nord15;

          "diffEditor.insertedTextBackground" = nord.diffAddedText;
          "diffEditor.removedTextBackground" = nord.diffRemovedText;

          "diffEditor.insertedLineBackground" = nord.diffAddedLine;
          "diffEditor.removedLineBackground" = nord.diffRemovedLine;

          # -- Integrated terminal

          "terminal.foreground" = nord.foregroundBright;

          "terminalCursor.foreground" = nord.foregroundPrimary;
          "terminalCursor.background" = nord.nord0;

          "terminal.selectionBackground" = nord.accentSelectionTerminal;
        };
      };

      # Match neovim-flake:
      #   vim.g.nord_italic = false
      "editor.tokenColorCustomizations" = {
        "[Nord]" = {
          comments = {
            fontStyle = "";
          };

          textMateRules = [
            {
              name = "Disable Nord italics";
              scope = [
                "emphasis"
                "text.html.basic constant.other.inline-data"
                "text.html.markdown markup.italic"
                "source.css.scss variable.interpolation"
                "text.xml string.unquoted.cdata"
                "text.xml string.unquoted.cdata punctuation.definition.string"
              ];
              settings = {
                fontStyle = "";
              };
            }
          ];
        };
      };
    };
  };
}
