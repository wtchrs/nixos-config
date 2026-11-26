{
  flake,
  pkgs,
  ...
}:

let
  inherit (pkgs.stdenv.hostPlatform) system;
  neovim = flake.self.packages.${system}.neovim;
in
{
  environment.systemPackages = with pkgs; [
    neovim
    vim
    git
    curl
    tmux
    htop
  ];

  programs = {
    zsh = {
      enable = true;
      # Each user's Home Manager zsh configuration runs compinit. A global run repeats it.
      enableGlobalCompInit = false;
    };
    mtr.enable = true;
  };
}
