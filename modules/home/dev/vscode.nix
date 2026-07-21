{ pkgs, ... }:

let
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
    require("mini.surround").setup()

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

    ---- Explorer / picker / file

    -- Replace neo-tree
    map("n", "<leader>e", vsc("workbench.view.explorer"), opts("Explorer"))
    map(
      "n",
      "<leader>fe",
      vsc("workbench.files.action.focusFilesExplorer"),
      opts("Focus File Explorer")
    )

    -- Replace Snacks picker
    map(
      "n",
      "<leader>ff",
      vsc("workbench.action.quickOpen"),
      opts("Find Files")
    )
    map(
      "n",
      "<leader>fg",
      vsc("workbench.action.findInFiles"),
      opts("Find in Files")
    )
    map(
      "n",
      "<leader>fb",
      vsc("workbench.action.showAllEditors"),
      opts("Find Buffers")
    )
    map(
      "n",
      "<leader>fr",
      vsc("workbench.action.openRecent"),
      opts("Recent Files")
    )
    map(
      "n",
      "<leader>fn",
      vsc("workbench.action.files.newUntitledFile"),
      opts("New File")
    )

    map(
      "n",
      "<leader>?",
      vsc("workbench.action.showCommands"),
      opts("Command Palette")
    )

    ---- Buffer / VSCode editor tab

    local previous_editor = vsc("workbench.action.previousEditor")
    local next_editor = vsc("workbench.action.nextEditor")
    local alternate_editor = vsc("workbench.action.openPreviousRecentlyUsedEditor")

    map("n", "<S-h>", previous_editor, opts("Previous Buffer"))
    map("n", "<S-l>", next_editor, opts("Next Buffer"))
    map("n", "[b", previous_editor, opts("Previous Buffer"))
    map("n", "]b", next_editor, opts("Next Buffer"))

    map("n", "<leader>bb", alternate_editor, opts("Other Buffer"))
    map("n", "<leader>`", alternate_editor, opts("Other Buffer"))

    map(
      "n",
      "<leader>bd",
      vsc("workbench.action.closeActiveEditor"),
      opts("Delete Buffer")
    )
    map(
      "n",
      "<leader>bo",
      vsc("workbench.action.closeOtherEditors"),
      opts("Delete Other Buffers")
    )

    map(
      "n",
      "<leader>uz",
      vsc("workbench.action.toggleZenMode"),
      opts("Toggle Zen Mode")
    )

    ---- Code actions / LSP

    map(
      "n",
      "<leader>ca",
      vsc("editor.action.quickFix"),
      opts("Code Action")
    )
    map(
      "n",
      "<leader>cr",
      vsc("editor.action.rename"),
      opts("Rename Symbol")
    )
    map(
      "n",
      "<leader>cs",
      vsc("workbench.action.gotoSymbol"),
      opts("Document Symbols")
    )
    map(
      "n",
      "<leader>sS",
      vsc("workbench.action.showAllSymbols"),
      opts("Workspace Symbols")
    )

    map(
      "n",
      "<leader>cf",
      vsc("editor.action.formatDocument"),
      opts("Format Document")
    )
    map(
      "x",
      "<leader>cf",
      vsc("editor.action.formatSelection"),
      opts("Format Selection")
    )

    ---- Diagnostics / quickfix

    map(
      "n",
      "<leader>cd",
      vsc("editor.action.showHover"),
      opts("Hover Diagnostics")
    )

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

    map(
      "n",
      "<leader>xx",
      vsc("workbench.actions.view.problems"),
      opts("Problems")
    )

    ---- Git

    map(
      "n",
      "<leader>gg",
      vsc("workbench.view.scm"),
      opts("Source Control")
    )

    ---- Terminal

    map(
      "n",
      "<leader>ft",
      vsc("workbench.action.terminal.toggleTerminal"),
      opts("Terminal")
    )

    ---- Editor group / Neovim window

    map(
      "n",
      "<leader>-",
      vsc("workbench.action.splitEditorDown"),
      opts("Split Below")
    )
    map(
      "n",
      "<leader>|",
      vsc("workbench.action.splitEditorRight"),
      opts("Split Right")
    )
    map(
      "n",
      "<leader>wd",
      vsc("workbench.action.closeGroup"),
      opts("Close Editor Group")
    )
    map(
      "n",
      "<leader>wm",
      vsc("workbench.action.toggleMaximizeEditorGroup"),
      opts("Maximize Editor Group")
    )
    map(
      "n",
      "<leader>uz",
      vsc("workbench.action.toggleZenMode"),
      opts("Zen Mode")
    )

    ---- Debug

    map(
      "n",
      "<leader>db",
      vsc("editor.debug.action.toggleBreakpoint"),
      opts("Toggle Breakpoint")
    )
    map(
      "n",
      "<leader>dc",
      vsc("workbench.action.debug.continue"),
      opts("Debug Continue")
    )
    map(
      "n",
      "<leader>di",
      vsc("workbench.action.debug.stepInto"),
      opts("Debug Step Into")
    )
    map(
      "n",
      "<leader>do",
      vsc("workbench.action.debug.stepOver"),
      opts("Debug Step Over")
    )
    map(
      "n",
      "<leader>dO",
      vsc("workbench.action.debug.stepOut"),
      opts("Debug Step Out")
    )
    map(
      "n",
      "<leader>du",
      vsc("workbench.view.debug"),
      opts("Debug View")
    )

    ---- Miscellaneous

    map("n", "<leader>l", function()
      vscode.action("workbench.extensions.search", {
        args = { "@installed" },
      })
    end, opts("Installed Extensions"))

    map(
      "n",
      "<leader>uw",
      vsc("editor.action.toggleWordWrap"),
      opts("Toggle Word Wrap")
    )

    map(
      "n",
      "<leader>ui",
      vsc("editor.action.inspectTMScopes"),
      opts("Inspect Tokens and Scopes")
    )
  '';
in
{
  imports = [ ./vscodeTheme.nix ];

  # VSCode Neovim backend
  home.packages = [
    pkgs.neovim
  ];

  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    mutableExtensionsDir = false;

    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        asvetliakov.vscode-neovim
        jnoortheen.nix-ide
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
      };

      keybindings = [
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

        # -- File explorer
        {
          key = "space e";
          command = "workbench.action.toggleSidebarVisibility";
          when = ''
            (sideBarFocus ||
              activeEditor
              && !editorTextFocus
              && !sideBarFocus
              && !panelFocus
              && !auxiliaryBarFocus
              && !terminalFocus)
            && !inputFocus
            && activeViewlet == 'workbench.view.explorer'
          '';
        }
        {
          key = "space e";
          command = "workbench.view.explorer";
          when = ''
            (sideBarFocus ||
              activeEditor
              && !editorTextFocus
              && !sideBarFocus
              && !panelFocus
              && !auxiliaryBarFocus
              && !terminalFocus)
            && !inputFocus
            && (
              !sideBarVisible
              || activeViewlet != 'workbench.view.explorer'
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
