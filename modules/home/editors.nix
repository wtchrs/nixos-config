{ flake, pkgs, ... }:

let
  inherit (pkgs.stdenv.hostPlatform) system;
  neovim-flake = flake.inputs.neovim-flake.packages.${system}.default;
in
{
  home.packages = with pkgs; [
    neovim-flake
    vim
  ];
}
