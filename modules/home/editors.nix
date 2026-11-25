{ flake, pkgs, ... }:

let
  inherit (pkgs.stdenv.hostPlatform) system;
  neovim = flake.self.packages.${system}.neovim;
in
{
  home.packages = with pkgs; [
    neovim
    neopane
    vim
  ];

  home.sessionVariables.EDITOR = "nvim";
}
