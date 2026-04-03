_:

{
  imports = [
    ./starship.nix
    ./tmux.nix
    ./zsh.nix
  ];

  # Enable `command-not-found`
  programs = {
    nix-index = {
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

      shellAliases = {
        ls = "eza";
      };
    };
  };
}
