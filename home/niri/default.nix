{ pkgs, inputs, ... }:

{
  #nixpkgs.overlays = [
  #  inputs.niri.overlays.niri
  #];

  imports = [
    inputs.niri.homeModules.niri
    ./input.nix
    ./outputs.nix
    ./environments.nix
    ./autostarts.nix
    ./layout.nix
    ./animations.nix
    ./rules.nix
    ./keybinds.nix
  ];

  programs.niri = {
    enable = true;
    package = pkgs.niri-unstable;

    settings = {
      prefer-no-csd = true;
      screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";
    };
  };
}
