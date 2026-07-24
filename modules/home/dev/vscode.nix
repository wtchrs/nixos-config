{ pkgs, ... }:

let
  whichKeyCommand = key: name: command: {
    inherit
      key
      name
      command
      ;
    type = "command";
  };

  whichKeyGroup = key: name: bindings: {
    inherit
      key
      name
      bindings
      ;
    type = "bindings";
  };

  whichKeyBindings = [
    {
      key = "e";
      name = "Explorer";
      type = "conditional";
      bindings = [
        {
          key = "when:sideBarVisible && activeViewlet == 'workbench.view.explorer'";
          name = "Hide Explorer";
          type = "command";
          command = "workbench.action.toggleSidebarVisibility";
        }
        {
          key = "";
          name = "Show Explorer";
          type = "command";
          command = "workbench.view.explorer";
        }
      ];
    }

    (whichKeyGroup "f" "File..." [
      (whichKeyCommand "e" "Focus File Explorer" "workbench.files.action.focusFilesExplorer")
      (whichKeyCommand "f" "Find Files" "workbench.action.quickOpen")
      (whichKeyCommand "g" "Find in Files" "workbench.action.findInFiles")
      (whichKeyCommand "b" "Find Buffers" "workbench.action.showAllEditors")
      (whichKeyCommand "r" "Recent Files" "workbench.action.openRecent")
      (whichKeyCommand "n" "New File" "workbench.action.files.newUntitledFile")
      (whichKeyCommand "t" "Terminal" "workbench.action.terminal.toggleTerminal")
    ])

    (whichKeyCommand "?" "Command Palette" "workbench.action.showCommands")

    (whichKeyGroup "b" "Buffer..." [
      (whichKeyCommand "b" "Other Buffer" "workbench.action.openPreviousRecentlyUsedEditor")
      (whichKeyCommand "`" "Other Buffer" "workbench.action.openPreviousRecentlyUsedEditor")
      (whichKeyCommand "h" "Previous Buffer" "workbench.action.previousEditor")
      (whichKeyCommand "l" "Next Buffer" "workbench.action.nextEditor")
      (whichKeyCommand "d" "Delete Buffer" "workbench.action.closeActiveEditor")
      (whichKeyCommand "o" "Delete Other Buffers" "workbench.action.closeOtherEditors")
    ])

    (whichKeyGroup "u" "UI..." [
      (whichKeyCommand "z" "Toggle Zen Mode" "workbench.action.toggleZenMode")
      (whichKeyCommand "w" "Toggle Word Wrap" "editor.action.toggleWordWrap")
      (whichKeyCommand "i" "Inspect Tokens and Scopes" "editor.action.inspectTMScopes")
    ])

    (whichKeyGroup "c" "Code..." [
      (whichKeyCommand "a" "Code Action" "editor.action.quickFix")
      (whichKeyCommand "r" "Rename Symbol" "editor.action.rename")
      (whichKeyCommand "s" "Document Symbols" "workbench.action.gotoSymbol")
      (whichKeyCommand "f" "Format Document" "editor.action.formatDocument")
      (whichKeyCommand "d" "Hover Diagnostics" "editor.action.showHover")
    ])

    (whichKeyGroup "s" "Search..." [
      (whichKeyCommand "S" "Workspace Symbols" "workbench.action.showAllSymbols")
    ])

    (whichKeyGroup "x" "Diagnostics..." [
      (whichKeyCommand "x" "Problems" "workbench.actions.view.problems")
    ])

    (whichKeyGroup "g" "Git..." [
      (whichKeyCommand "g" "Source Control" "workbench.view.scm")
    ])

    (whichKeyCommand "-" "Split Below" "workbench.action.splitEditorDown")
    (whichKeyCommand "|" "Split Right" "workbench.action.splitEditorRight")

    (whichKeyGroup "w" "Window..." [
      (whichKeyCommand "h" "Focus Left Group" "workbench.action.focusLeftGroup")
      (whichKeyCommand "j" "Focus Below Group" "workbench.action.focusBelowGroup")
      (whichKeyCommand "k" "Focus Above Group" "workbench.action.focusAboveGroup")
      (whichKeyCommand "l" "Focus Right Group" "workbench.action.focusRightGroup")
      (whichKeyCommand "p" "Focus Previous Group" "workbench.action.focusPreviousGroup")

      (whichKeyCommand "H" "Decrease Group Width" "workbench.action.decreaseViewWidth")
      (whichKeyCommand "L" "Increase Group Width" "workbench.action.increaseViewWidth")
      (whichKeyCommand "J" "Decrease Group Height" "workbench.action.decreaseViewSize")
      (whichKeyCommand "K" "Increase Group Height" "workbench.action.increaseViewSize")

      (whichKeyCommand "d" "Close Editor Group" "workbench.action.closeGroup")
      (whichKeyCommand "m" "Maximize Editor Group" "workbench.action.toggleMaximizeEditorGroup")
    ])

    (whichKeyGroup "d" "Debug..." [
      (whichKeyCommand "b" "Toggle Breakpoint" "editor.debug.action.toggleBreakpoint")
      (whichKeyCommand "c" "Continue" "workbench.action.debug.continue")
      (whichKeyCommand "i" "Step Into" "workbench.action.debug.stepInto")
      (whichKeyCommand "o" "Step Over" "workbench.action.debug.stepOver")
      (whichKeyCommand "O" "Step Out" "workbench.action.debug.stepOut")
      (whichKeyCommand "u" "Debug View" "workbench.view.debug")
    ])

    (whichKeyCommand "l" "Installed Extensions" "workbench.extensions.action.showInstalledExtensions")
  ];

  vscodeNeovimInit = pkgs.writeText "vscode-neovim-init.lua" ''
    if not vim.g.vscode then
      return
    end

    vim.g.mapleader = " "
    vim.g.maplocalleader = "\\"

    vim.opt.clipboard = "unnamedplus"
    vim.opt.ignorecase = true
    vim.opt.smartcase = true
    vim.opt.hlsearch = true

    vim.opt.runtimepath:prepend("${pkgs.vimPlugins.mini-nvim}")
    require("mini.surround").setup({
      mappings = {
        add = "gsa",
        delete = "gsd",
        find = "gsf",
        find_left = "gsF",
        highlight = "gsh",
        replace = "gsr",
        suffix_last = "l",
        suffix_next = "n",
      },
    })

    local vscode = require("vscode")
    local map = vim.keymap.set

    local function vsc(command)
      return function()
        vscode.action(command)
      end
    end

    local function opts(description)
      return {
        noremap = true,
        silent = true,
        desc = description,
      }
    end

    ---- Default movement and search

    -- Move through soft-wrapped lines
    map(
      { "n", "x" },
      "j",
      "v:count == 0 ? 'gj' : 'j'",
      { expr = true, silent = true, desc = "Down" }
    )
    map(
      { "n", "x" },
      "k",
      "v:count == 0 ? 'gk' : 'k'",
      { expr = true, silent = true, desc = "Up" }
    )

    -- Process n/N consistently based on search direction
    map(
      "n",
      "n",
      "'Nn'[v:searchforward].'zv'",
      { expr = true, desc = "Next Search Result" }
    )
    map(
      "n",
      "N",
      "'nN'[v:searchforward].'zv'",
      { expr = true, desc = "Previous Search Result" }
    )

    map("n", "<Esc>", function()
      vim.cmd("nohlsearch")
      return "<Esc>"
    end, {
      expr = true,
      silent = true,
      desc = "Escape and Clear Search Highlight",
    })

    -- Keep the selection after indentation
    map("x", "<", "<gv", opts("Indent Left"))
    map("x", ">", ">gv", opts("Indent Right"))

    ---- Buffer / VSCode editor tab

    local previous_editor = vsc("workbench.action.previousEditor")
    local next_editor = vsc("workbench.action.nextEditor")

    map("n", "<S-h>", previous_editor, opts("Previous Buffer"))
    map("n", "<S-l>", next_editor, opts("Next Buffer"))
    map("n", "[b", previous_editor, opts("Previous Buffer"))
    map("n", "]b", next_editor, opts("Next Buffer"))

    ---- Code actions / LSP

    map(
      "x",
      "<leader>cf",
      vsc("editor.action.formatSelection"),
      opts("Format Selection")
    )

    ---- Diagnostics / quickfix

    map(
      "n",
      "]d",
      vsc("editor.action.marker.next"),
      opts("Next Diagnostic")
    )
    map(
      "n",
      "[d",
      vsc("editor.action.marker.prev"),
      opts("Previous Diagnostic")
    )

    map(
      "n",
      "]q",
      vsc("editor.action.marker.nextInFiles"),
      opts("Next Workspace Diagnostic")
    )
    map(
      "n",
      "[q",
      vsc("editor.action.marker.prevInFiles"),
      opts("Previous Workspace Diagnostic")
    )

  '';
in
{
  imports = [ ./vscodeTheme.nix ];

  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    mutableExtensionsDir = false;

    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        asvetliakov.vscode-neovim
        jnoortheen.nix-ide
        mkhl.direnv
        vspacecode.whichkey
      ];

      userSettings = {
        "editor.formatOnSave" = true;

        "editor.lineNumbers" = "relative";
        "editor.minimap.enabled" = false;
        "editor.stickyScroll.enabled" = false;
        "editor.cursorSurroundingLines" = 8;

        # -- Font
        "editor.fontFamily" = "'Sarasa Mono K', monospace";
        "editor.fontSize" = 15;

        # -- Theme
        #"workbench.colorTheme" = "Light 2026";

        "workbench.editor.enablePreview" = false;
        "workbench.tree.enableStickyScroll" = false;
        "workbench.activityBar.location" = "top";

        # -- Window
        "window.titleBarStyle" = "custom";
        "window.controlsStyle" = "hidden";

        # -- VSCode Neovim
        "vscode-neovim.neovimExecutablePaths.linux" = "${pkgs.neovim}/bin/nvim";
        "vscode-neovim.neovimInitVimPaths.linux" = "${vscodeNeovimInit}";
        "vscode-neovim.NVIM_APPNAME" = "vscode-neovim";
        "vscode-neovim.neovimClean" = false;

        "vscode-neovim.ctrlKeysForNormalMode" = [
          "a"
          "b"
          "c"
          "d"
          "e"
          "f"
          "i"
          "m"
          "o"
          "r"
          "t"
          "u"
          "v"
          "w"
          "x"
          "y"
          "z"
          "]"
          "backspace"
          "delete"
        ];

        "extensions.experimental.affinity" = {
          "asvetliakov.vscode-neovim" = 1;
        };

        # -- Which Key
        "whichkey.bindings" = whichKeyBindings;
        "whichkey.sortOrder" = "custom";

        # -- direnv
        "direnv.restart.automatic" = true;
        "direnv.watchForChanges" = true;
      };

      keybindings = [
        # -- Which Key
        {
          key = "space";
          command = "whichkey.show";
          when = ''
            (editorTextFocus && neovim.mode == normal)
            || (
              !editorTextFocus
              && !inputFocus
              && !terminalFocus
              && (
                activeEditor
                || sideBarFocus
              )
            )
          '';
        }
        {
          key = "backspace";
          command = "whichkey.undoKey";
          when = "whichkeyVisible";
        }
        # Send condition to whichkey
        {
          key = "e";
          command = "whichkey.triggerKey";
          args = {
            key = "e";
            when = "sideBarVisible && activeViewlet == 'workbench.view.explorer'";
          };
          when = ''
            whichkeyVisible
            && sideBarVisible
            && activeViewlet == 'workbench.view.explorer'
          '';
        }

        # -- Window focus
        {
          key = "ctrl+h";
          command = "workbench.action.focusLeftGroup";
          when = "editorTextFocus && neovim.mode != insert";
        }
        {
          key = "ctrl+j";
          command = "workbench.action.focusBelowGroup";
          when = "editorTextFocus && neovim.mode != insert";
        }
        {
          key = "ctrl+k";
          command = "workbench.action.focusAboveGroup";
          when = "editorTextFocus && neovim.mode != insert";
        }
        {
          key = "ctrl+l";
          command = "workbench.action.focusRightGroup";
          when = "editorTextFocus && neovim.mode != insert";
        }
        {
          key = "ctrl+\\";
          command = "workbench.action.focusPreviousGroup";
          when = "editorTextFocus && neovim.mode != insert";
        }

        # -- Window resizing
        {
          key = "ctrl+up";
          command = "workbench.action.increaseViewSize";
          when = "editorTextFocus && neovim.mode != insert";
        }
        {
          key = "ctrl+down";
          command = "workbench.action.decreaseViewSize";
          when = "editorTextFocus && neovim.mode != insert";
        }
        {
          key = "ctrl+left";
          command = "workbench.action.decreaseViewWidth";
          when = "editorTextFocus && neovim.mode != insert";
        }
        {
          key = "ctrl+right";
          command = "workbench.action.increaseViewWidth";
          when = "editorTextFocus && neovim.mode != insert";
        }

        # -- Line movement
        {
          key = "alt+j";
          command = "editor.action.moveLinesDownAction";
          when = "editorTextFocus && !editorReadonly";
        }
        {
          key = "alt+k";
          command = "editor.action.moveLinesUpAction";
          when = "editorTextFocus && !editorReadonly";
        }

        # -- Terminal
        {
          key = "ctrl+/";
          command = "workbench.action.terminal.toggleTerminal";
          #when = "editorTextFocus && neovim.mode != insert";
        }

        # -- Editor focus
        {
          key = "escape";
          command = "workbench.action.focusActiveEditorGroup";
          when = ''
            activeEditor
            && !editorTextFocus
            && !inputFocus
            && (
              sideBarFocus
              || panelFocus
              || auxiliaryBarFocus
            )
          '';
        }

        # -- Open buffers
        {
          key = "shift+h";
          command = "workbench.action.previousEditor";
          when = ''
            activeEditor
            && !editorTextFocus
            && !inputFocus
            && !sideBarFocus
            && !panelFocus
            && !auxiliaryBarFocus
            && !terminalFocus
          '';
        }
        {
          key = "shift+l";
          command = "workbench.action.nextEditor";
          when = ''
            activeEditor
            && !editorTextFocus
            && !inputFocus
            && !sideBarFocus
            && !panelFocus
            && !auxiliaryBarFocus
            && !terminalFocus
          '';
        }
      ];
    };
  };
}
