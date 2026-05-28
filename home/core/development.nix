{ inputs, pkgs, ... }:

let
  inherit (pkgs.stdenv.hostPlatform) system;
  neovim-flake = inputs.neovim-flake.packages.${system}.default;
in
{
  home.packages = with pkgs; [
    # Editors
    neovim-flake
    vim

    # JavaScript runtimes and package managers
    nodejs
    pnpm

    # Nix tooling
    nix-output-monitor
  ];

  programs = {
    direnv.enable = true;
    direnv.nix-direnv.enable = true;
  };
}
