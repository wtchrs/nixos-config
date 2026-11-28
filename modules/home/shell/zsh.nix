{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.packages = with pkgs; [
    zsh-completions
  ];

  programs.zsh = {
    enable = true;

    enableCompletion = true;
    autosuggestion.enable = true;

    # bindkey -e
    defaultKeymap = "emacs";

    history = {
      path = "${config.home.homeDirectory}/.zsh_history";
      size = 100000;
      save = 10000000;
      ignoreDups = true;
      ignoreSpace = true;
      extended = true;
      share = true;
    };

    # Enter a directory by typing its name.
    autocd = true;

    setOptions = [
      "HIST_REDUCE_BLANKS"
      "INC_APPEND_HISTORY_TIME"
      # Show an expanded history reference such as !! before it runs.
      "HIST_VERIFY"
      # Keep Ctrl+S and Ctrl+Q from freezing and resuming the terminal.
      "NO_FLOW_CONTROL"
    ];

    initContent = lib.mkMerge [
      # after compinit (570)
      (lib.mkOrder 600 ''
        # fzf-tab
        source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh

        zstyle ':fzf-tab:*' fzf-command fzf
        zstyle ':fzf-tab:*' fzf-pad 4
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color=always "$realpath"'
        zstyle ':completion:*:descriptions' format '[%d]'
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
        zstyle ':completion:*' menu no
      '')

      # Line editing keys and completion matching that oh-my-zsh used to set.
      (lib.mkOrder 800 ''
        # Word motions stop at every non-alphanumeric character, such as / and -.
        WORDCHARS=""

        # zsh binds none of these keys by default. Home and End send different
        # sequences in Ghostty (normal and application mode), tmux, and the
        # Linux console.
        bindkey '^[[H' beginning-of-line
        bindkey '^[OH' beginning-of-line
        bindkey '^[[1~' beginning-of-line
        bindkey '^[[F' end-of-line
        bindkey '^[OF' end-of-line
        bindkey '^[[4~' end-of-line
        bindkey '^[[3~' delete-char
        bindkey '^[[1;5C' forward-word   # Ctrl+Right
        bindkey '^[[1;5D' backward-word  # Ctrl+Left

        autoload -Uz edit-command-line
        zle -N edit-command-line
        bindkey '^X^E' edit-command-line

        # Case-insensitive completion. fzf-tab completes from the same matches.
        zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|=*' 'l:|=* r:|=*'
      '')

      # oh-my-zsh plugins without the framework. The git plugin needs
      # git_current_branch from lib/git.zsh. Its async prompt needs the
      # framework, so lib/git.zsh uses the synchronous version.
      (lib.mkOrder 800 ''
        zstyle ':omz:alpha:lib:git' async-prompt no
        source ${pkgs.oh-my-zsh}/share/oh-my-zsh/lib/git.zsh
        source ${pkgs.oh-my-zsh}/share/oh-my-zsh/plugins/git/git.plugin.zsh
        source ${pkgs.oh-my-zsh}/share/oh-my-zsh/plugins/sudo/sudo.plugin.zsh
      '')

      (lib.mkOrder 1000 ''
        # path
        path=("$HOME/.local/bin" $path)

        # pnpm
        export PNPM_HOME="$HOME/.local/share/pnpm"
        mkdir -p "$PNPM_HOME"
        path+=("$PNPM_HOME/bin")

        # fzf
        _fzf_compgen_path() { fd --hidden --exclude .git . "$1"; }
        _fzf_compgen_dir()  { fd --type=d --hidden --exclude .git . "$1"; }
      '')

      (lib.mkOrder 1200 ''
        # fast-syntax-highlighting
        source ${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
      '')

      (lib.mkOrder 1500 ''eval "$(${pkgs.rgrc}/bin/rgrc --aliases --except ls)" '')
    ];
  };
}
