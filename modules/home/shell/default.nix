{ pkgs, ... }:

{
  imports = [
    ./zsh.nix
    ./starship.nix
    ./atuin.nix
    ./tmux
    ./zellij
    ./lsd
    ./colored-man.nix
  ];

  home.packages = with pkgs; [
    fd
    rgrc
  ];

  programs = {
    bat = {
      enable = true;
      config = {
        theme = "Nord";
      };
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;

      defaultCommand = "${pkgs.fd}/bin/fd --hidden --strip-cwd-prefix --exclude .git";
      fileWidget.command = "${pkgs.fd}/bin/fd --hidden --strip-cwd-prefix --exclude .git";
      changeDirWidget.command = "${pkgs.fd}/bin/fd --type=d --hidden --strip-cwd-prefix --exclude .git";

      # Disable fzf Ctrl+R binding to avoid conflicts with atuin
      historyWidget.command = "";
    };

    broot = {
      enable = true;
      enableZshIntegration = true;
    };

    zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };

    bash = {
      enable = true;
      enableCompletion = true;

      bashrcExtra = ''
        export PATH="$PATH:$HOME/.local/bin"
      '';

      initExtra = ''
        eval "$(${pkgs.rgrc}/bin/rgrc --aliases --except ls)"
      '';

      shellAliases = {
        bat = "bat --paging=never";
      };
    };
  };
}
