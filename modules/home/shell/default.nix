{ pkgs, ... }:

{
  imports = [
    ./zsh.nix
    ./starship.nix
    ./tmux
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
      fileWidgetCommand = "${pkgs.fd}/bin/fd --hidden --strip-cwd-prefix --exclude .git";
      changeDirWidgetCommand = "${pkgs.fd}/bin/fd --type=d --hidden --strip-cwd-prefix --exclude .git";
    };

    broot = {
      enable = true;
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
