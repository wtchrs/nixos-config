{ pkgs, ... } :

{
  imports = [
    ./hyprland
    ./waybar
    ./programs/alacritty.nix
    ./programs/dunst.nix
    ./programs/rofi
    ./misc/fonts.nix
    ./misc/input.nix
    ./misc/cursor.nix
  ];

  home.packages = with pkgs; [
    hyprshot
    jetbrains-toolbox
  ];
}
