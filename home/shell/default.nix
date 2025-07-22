{ config, pkgs, ... } :

{
  imports = [
    ./starship.nix
    ./tmux.nix
  ];

  # Enable `command-not-found`
  programs.nix-index = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;

    bashrcExtra = ''
      export PATH="$PATH:$HOME/.local/bin"
    '';

    shellAliases = {
      ls = "exa";
    };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    # syntaxHighlighting.enable = true;

    history = {
      path = "$HOME/.zsh_history";
      size = 100000;
      append = true;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
      extended = true;
    };

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "sudo"
      ];
    };

    initContent = ''
      setopt incappendhistory
      bindkey -e # for zsh emacs mode shortcuts
      bindkey '^H' backward-kill-word
    '';

    shellAliases = {
      ls = "exa";
    };
  };
}
