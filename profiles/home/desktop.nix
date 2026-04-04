{ pkgs, inputs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  imports = [
    ../../home/niri
    ../../home/quickshell
    ../../home/programs/ghostty.nix
    ../../home/programs/dunst.nix
    ../../home/programs/btop.nix
    ../../home/misc/fonts.nix
    ../../home/misc/input.nix
    ../../home/misc/cursor.nix
  ];

  home.packages = with pkgs; [
    jetbrains-toolbox
    inputs.zen-browser.packages.${system}.default
    spotify
  ];

  programs = {
    vesktop.enable = true;
  };
}
