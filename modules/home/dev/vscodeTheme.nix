{ pkgs, ... }:

let
  nord = rec {
    # -- Transparent / base window surfaces

    transparent = "#00000000";

    # Single background tint for .monaco-workbench.
    background = "#000000A6";

    # Used for floating UI and special states.
    backgroundStrong = "#000000D9";
    backgroundInactive = "#000000B3";
    backgroundPopup = "#0b0d12F2";
    backgroundInput = "#00000033";
    shadow = "#00000066";

    # -- Nord base palette

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
    accentMedium = "#88c0d066";
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

  vibrancyCss = pkgs.writeText "vscode-nord-vibrancy.css" ''
    html,
    body {
      background: transparent !important;
    }

    /* Single fixed background tint for the workbench. */
    .monaco-workbench,
    .monaco-workbench.fullscreen {
      background-color: ${nord.background} !important;
    }

    /* Keep structural wrappers transparent. */
    .monaco-workbench .part.editor,
    .monaco-workbench .part.editor > .content,
    .monaco-workbench .part.editor > .content > .one-editor-silo,
    .monaco-workbench .part.editor
      > .content
      > .one-editor-silo
      > .container,
    .editor-group-container,
    .editor-container:not(.modal-editor-part .editor-container) {
      background-color: transparent !important;
    }

    .monaco-workbench .part.titlebar,
    .monaco-workbench .part.activitybar,
    .monaco-workbench .part.sidebar,
    .monaco-workbench .part.auxiliarybar,
    .monaco-workbench .part.panel,
    .monaco-workbench .part.statusbar {
      background-color: transparent !important;
    }

    .editor-group-container > .title,
    .editor-group-container > .tabs-and-actions-container,
    .editor-group-container
      > .tabs-and-actions-container
      > .monaco-scrollable-element,
    .editor-group-container
      > .tabs-and-actions-container
      .tabs-container,
    .editor-group-container > .breadcrumbs-below-tabs,
    .monaco-breadcrumbs {
      background-color: transparent !important;
    }

    .monaco-editor,
    .monaco-editor-background,
    .monaco-editor .margin,
    .monaco-editor .overflow-guard {
      background-color: transparent !important;
    }

    .monaco-list,
    .monaco-list .monaco-list-rows,
    .pane-body,
    .pane-header {
      background-color: transparent !important;
    }

    .extension-editor,
    .preferences-editor,
    .preferences-editor > .preferences-header,
    .preferences-editor > .preferences-editors-container,
    .getting-started,
    .gettingStartedContainer,
    .notebookOverlay.notebook-editor,
    .cell-statusbar-container {
      background-color: transparent !important;
    }

    .terminal-outer-container,
    .terminal-wrapper,
    .xterm,
    .xterm-viewport,
    .xterm-screen,
    .xterm-rows {
      background-color: transparent !important;
    }

    /* Give popups an opaque layer over the wallpaper. */
    .quick-input-widget,
    .context-view .monaco-menu-container,
    .monaco-hover,
    .monaco-editor-hover,
    .suggest-widget,
    .notification-toast,
    .notifications-center,
    .modal-editor-part > .content,
    .modal-editor-part .editor-container {
      background-color: ${nord.backgroundPopup} !important;
    }
  '';
in
{
  programs.vscode.profiles.default = {
    extensions = with pkgs.vscode-extensions; [
      arcticicestudio.nord-visual-studio-code
      illixion.vscode-vibrancy-continued
    ];

    userSettings = {
      # -- VSCode Vibrancy
      "vscode_vibrancy.type" = "transparent";
      "vscode_vibrancy.windowMode" = "frameless-transparent";

      "vscode_vibrancy.opacity" = 0.0;
      #"vscode_vibrancy.backgroundOverride" = "#000000";

      "vscode_vibrancy.theme" = "Custom theme (use imports)";
      "vscode_vibrancy.imports" = [
        "${vibrancyCss}"
      ];

      "vscode_vibrancy.preventFlash" = true;
      "vscode_vibrancy.disableColorCustomizations" = true;

      "terminal.integrated.gpuAcceleration" = "off";

      # -- Nord theme

      "workbench.colorTheme" = "Nord";
      "workbench.preferredDarkColorTheme" = "Nord";
      "window.autoDetectColorScheme" = false;

      # Keep Nord semantic highlighting.
      "editor.semanticHighlighting.enabled" = true;

      # Ghostty configuration disables ligatures.
      "editor.fontLigatures" = false;

      # Preserve the configured ANSI colors instead of increasing contrast.
      "terminal.integrated.minimumContrastRatio" = 1;
      "terminal.integrated.fontFamily" = "'Sarasa Mono K', monospace";
      "terminal.integrated.fontSize" = 14;
      "terminal.integrated.stickyScroll.enabled" = false;

      "workbench.colorCustomizations" = {
        "[Nord]" = {
          # -- Global foreground / focus

          "foreground" = nord.foregroundPrimary;

          "focusBorder" = nord.nord8;
          "contrastActiveBorder" = nord.transparent;
          "contrastBorder" = nord.transparent;

          # -- Main structural surfaces
          # CSS provides the background; nested surfaces stay transparent.

          "editor.background" = nord.transparent;
          "editorGroup.background" = nord.transparent;
          "editorGroup.emptyBackground" = nord.transparent;
          "editorPane.background" = nord.transparent;
          "editorGutter.background" = nord.transparent;
          "minimap.background" = nord.transparent;

          "sideBar.background" = nord.transparent;

          "panel.background" = nord.transparent;
          "terminal.background" = nord.transparent;

          "activityBar.background" = nord.transparent;

          "editorGroupHeader.tabsBackground" = nord.transparent;
          "editorGroupHeader.noTabsBackground" = nord.transparent;
          "editorGroupHeader.tabsBorder" = nord.transparent;

          "breadcrumb.background" = nord.transparent;

          "titleBar.activeBackground" = nord.transparent;
          "titleBar.inactiveBackground" = nord.transparent;

          "statusBar.background" = nord.transparent;
          "statusBar.noFolderBackground" = nord.transparent;

          # -- Editor-based pages

          "welcomePage.background" = nord.transparent;
          "walkThrough.embeddedEditorBackground" = nord.transparent;

          "notebook.editorBackground" = nord.transparent;
          "notebook.cellEditorBackground" = nord.transparent;

          # -- Floating widgets

          "editorWidget.background" = nord.backgroundPopup;
          "editorHoverWidget.background" = nord.backgroundPopup;
          "editorSuggestWidget.background" = nord.backgroundPopup;

          "quickInput.background" = nord.backgroundPopup;
          "dropdown.background" = nord.backgroundPopup;
          "menu.background" = nord.backgroundPopup;

          "notifications.background" = nord.backgroundPopup;
          "notificationCenterHeader.background" = nord.backgroundStrong;

          # -- Inputs

          "input.background" = nord.backgroundInput;
          "input.foreground" = nord.foregroundBright;
          "input.placeholderForeground" = nord.foregroundSubtle;
          "input.border" = nord.border;

          "quickInputList.focusBackground" = nord.surfaceStrong;
          "quickInputList.focusForeground" = nord.foregroundBright;

          # -- Editor

          "editor.foreground" = nord.foregroundPrimary;
          "editorCursor.foreground" = nord.foregroundPrimary;

          "editorLineNumber.foreground" = nord.nord3;
          "editorLineNumber.activeForeground" = nord.foregroundBright;

          "editorWhitespace.foreground" = nord.whitespace;

          "editorIndentGuide.background1" = nord.surfaceWeak;
          "editorIndentGuide.activeBackground1" = nord.accentStrong;

          "editor.lineHighlightBackground" = nord.surfaceLine;
          "editor.lineHighlightBorder" = nord.transparent;

          "editor.selectionBackground" = nord.accentSelection;
          "editor.inactiveSelectionBackground" = nord.accentWeak;
          "editor.selectionHighlightBackground" = nord.accentVeryWeak;

          "editor.findMatchBackground" = nord.accentMedium;
          "editor.findMatchHighlightBackground" = nord.accentWeak;

          "editorBracketMatch.background" = nord.accentWeak;
          "editorBracketMatch.border" = nord.nord8;

          # -- Bracket pair colorization

          "editorBracketHighlight.foreground1" = nord.nord8;
          "editorBracketHighlight.foreground2" = nord.nord15;
          "editorBracketHighlight.foreground3" = nord.nord13;
          "editorBracketHighlight.foreground4" = nord.nord14;
          "editorBracketHighlight.foreground5" = nord.nord9;
          "editorBracketHighlight.foreground6" = nord.nord12;

          "editorBracketHighlight.unexpectedBracket.foreground" = nord.nord11;

          # -- Tabs / editor groups

          "editorGroup.border" = nord.border;

          "tab.activeBackground" = nord.surfaceWeak;
          "tab.inactiveBackground" = nord.transparent;
          "tab.hoverBackground" = nord.surfaceLine;

          "tab.activeForeground" = nord.foregroundBright;
          "tab.inactiveForeground" = nord.foregroundMuted;
          "tab.unfocusedActiveForeground" = nord.foregroundStrong;
          "tab.unfocusedInactiveForeground" = nord.foregroundSubtle;

          "tab.activeBorder" = nord.transparent;
          "tab.activeBorderTop" = nord.nord8;
          "tab.unfocusedActiveBorderTop" = nord.accentBorder;

          # -- Sidebar / lists

          "sideBar.foreground" = nord.foregroundPrimary;
          "sideBar.border" = nord.border;

          "sideBarTitle.foreground" = nord.foregroundBright;

          "sideBarSectionHeader.background" = nord.transparent;
          "sideBarSectionHeader.foreground" = nord.foregroundSecondary;
          "sideBarSectionHeader.border" = nord.border;

          "list.activeSelectionBackground" = nord.surfaceStrong;
          "list.activeSelectionForeground" = nord.foregroundBright;

          "list.inactiveSelectionBackground" = nord.surfaceMedium;
          "list.inactiveSelectionForeground" = nord.foregroundSecondary;

          "list.hoverBackground" = nord.surfaceHover;
          "list.hoverForeground" = nord.foregroundBright;

          "list.focusBackground" = nord.surfaceAltStrong;
          "list.focusForeground" = nord.foregroundBright;

          "list.highlightForeground" = nord.nord8;

          # -- Activity bar

          "activityBar.foreground" = nord.foregroundPrimary;
          "activityBar.inactiveForeground" = nord.foregroundSubtle;

          "activityBar.activeBorder" = nord.nord8;
          "activityBar.border" = nord.transparent;

          "activityBarBadge.background" = nord.nord8;
          "activityBarBadge.foreground" = nord.nord0;

          # -- Panel / status bar

          "panel.border" = nord.border;

          "panelTitle.activeBorder" = nord.nord8;
          "panelTitle.activeForeground" = nord.nord8;
          "panelTitle.inactiveForeground" = nord.foregroundDim;

          "statusBar.foreground" = nord.foregroundPrimary;
          "statusBar.border" = nord.transparent;

          "statusBar.debuggingBackground" = nord.debugBackground;
          "statusBar.debuggingForeground" = nord.foregroundBright;

          "statusBarItem.hoverBackground" = nord.surfaceAltMedium;
          "statusBarItem.activeBackground" = nord.surfacePressed;

          "statusBarItem.prominentBackground" = nord.surfaceMedium;
          "statusBarItem.prominentHoverBackground" = nord.surfaceAltStrong;

          # -- Buttons

          "button.background" = nord.accentButton;
          "button.foreground" = nord.nord0;
          "button.hoverBackground" = nord.accentAltButton;

          "button.secondaryBackground" = nord.surfaceAltStrong;
          "button.secondaryForeground" = nord.foregroundSecondary;
          "button.secondaryHoverBackground" = nord.surfacePressedStrong;

          # -- Scrollbars

          "scrollbar.shadow" = nord.shadow;

          "scrollbarSlider.background" = nord.surfaceAltWeak;
          "scrollbarSlider.hoverBackground" = nord.surfacePressed;
          "scrollbarSlider.activeBackground" = nord.accentStrong;

          # -- Diagnostics

          "editorError.foreground" = nord.nord11;
          "editorWarning.foreground" = nord.nord13;
          "editorInfo.foreground" = nord.nord8;
          "editorHint.foreground" = nord.nord7;

          "problemsErrorIcon.foreground" = nord.nord11;
          "problemsWarningIcon.foreground" = nord.nord13;
          "problemsInfoIcon.foreground" = nord.nord8;

          # -- Git

          "gitDecoration.addedResourceForeground" = nord.nord14;
          "gitDecoration.modifiedResourceForeground" = nord.nord13;
          "gitDecoration.deletedResourceForeground" = nord.nord11;
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

          "terminal.ansiBlack" = nord.nord1;
          "terminal.ansiBrightBlack" = nord.nord3;

          "terminal.ansiRed" = nord.nord11;
          "terminal.ansiBrightRed" = nord.nord11;

          "terminal.ansiGreen" = nord.nord14;
          "terminal.ansiBrightGreen" = nord.nord14;

          "terminal.ansiYellow" = nord.nord13;
          "terminal.ansiBrightYellow" = nord.nord13;

          "terminal.ansiBlue" = nord.nord9;
          "terminal.ansiBrightBlue" = nord.nord9;

          "terminal.ansiMagenta" = nord.nord15;
          "terminal.ansiBrightMagenta" = nord.nord15;

          "terminal.ansiCyan" = nord.nord8;
          "terminal.ansiBrightCyan" = nord.nord7;

          "terminal.ansiWhite" = nord.nord5;
          "terminal.ansiBrightWhite" = nord.nord6;
        };
      };

      # Match neovim-flake:
      #   vim.g.nord_italic = false
      "editor.tokenColorCustomizations" = {
        "[Nord]" = {
          comments = {
            foreground = nord.nord3Bright;
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
