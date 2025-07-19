{ config, pkgs, username, ... } :

{
  imports = [
    ./programs
    ./hyprland
    ./misc/fonts.nix
    ./misc/i18n.nix
  ];
}
