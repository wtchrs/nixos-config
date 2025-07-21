{ pkgs, ... } :

{
  imports = [
    ./hyprland
    ./waybar
    ./programs/alacritty.nix
    ./misc/fonts.nix
    ./misc/input.nix
  ];

  home.packages = with pkgs; [
    hyprshot
  ];
}
