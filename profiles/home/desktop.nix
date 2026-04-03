{ pkgs, ... }:

{
  imports = [
    ../../home/hyprland
    ../../home/niri
    ../../home/quickshell
    ../../home/programs/alacritty.nix
    ../../home/programs/ghostty.nix
    ../../home/programs/dunst.nix
    ../../home/misc/fonts.nix
    ../../home/misc/input.nix
    ../../home/misc/cursor.nix
  ];

  home.packages = with pkgs; [
    hyprshot
    jetbrains-toolbox
    walker
  ];
}
