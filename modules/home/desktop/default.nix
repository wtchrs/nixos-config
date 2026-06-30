{
  flake,
  lib,
  pkgs,
  ...
}:

let
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  imports = [
    ./niri
    ./desktopShell.nix
    ./ghostty.nix
    ./dunst.nix
    ./obsidian.nix

    ./misc/fonts.nix
    ./misc/input.nix
    ./misc/cursor.nix
    ./misc/clipboard.nix
  ];

  home.packages =
    with pkgs;
    [
      jetbrains-toolbox
      flake.inputs.zen-browser.packages.${system}.default
      brightnessctl
      nautilus
      loupe
    ]
    ++ lib.optional (lib.meta.availableOn pkgs.stdenv.hostPlatform spotify) spotify;

  programs = {
    vesktop.enable = true;
  };

  xdg.terminal-exec = {
    enable = true;
    settings = {
      default = [ "com.mitchellh.ghostty.desktop" ];
      niri = [ "com.mitchellh.ghostty.desktop" ];
    };
  };

  services.tailscale-systray.enable = true;
}
