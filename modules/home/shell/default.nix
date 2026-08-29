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
    ./fzf.nix
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
