{
  flake,
  pkgs,
  ...
}:

let
  inherit (pkgs.stdenv.hostPlatform) system;
  neovim-flake = flake.inputs.neovim-flake.packages.${system}.default;
in
{
  environment.systemPackages = with pkgs; [
    neovim-flake
    vim
    git
    curl
    tmux
    htop
  ];

  programs = {
    zsh.enable = true;
    mtr.enable = true;
  };
}
