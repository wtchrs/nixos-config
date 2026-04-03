{ config, pkgs, lib, ... }:

{
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

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "sudo"
      ];
    };

    setOptions = [
      "HIST_REDUCE_BLANKS"
      "INC_APPEND_HISTORY_TIME"
    ];

    initContent = lib.mkMerge [
      # after compinit
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

      (lib.mkOrder 1000 ''
        # path
        path=("$HOME/.local/bin" $path)

        # editor
        export EDITOR=nvim

        # fzf
        _fzf_compgen_path() { fd --hidden --exclude .git . "$1"; }
        _fzf_compgen_dir()  { fd --type=d --hidden --exclude .git . "$1"; }
      '')

      (lib.mkOrder 1200 ''
        # fast-syntax-highlighting
        source ${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
      '')
    ];

    shellAliases = {
      ls = "eza --icons=always";
      ll="eza --icons=always -aal";
      cat = "bat --paging=never";
    };
  };

  programs.bat = {
    enable = true;
    config = {
      theme = "Nord";
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;

    defaultCommand = "${pkgs.fd}/bin/fd --hidden --strip-cwd-prefix --exclude .git";
    fileWidgetCommand = "${pkgs.fd}/bin/fd --hidden --strip-cwd-prefix --exclude .git";
    changeDirWidgetCommand = "${pkgs.fd}/bin/fd --type=d --hidden --strip-cwd-prefix --exclude .git";
  };

  programs.broot = {
    enable = true;
    enableZshIntegration = true;
  };

  home.packages = with pkgs; [
    fd
    zsh-completions
  ];
}
