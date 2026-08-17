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
    ./gnome
    ./kde-plasma
    ./desktopShell.nix
    ./ghostty
    ./dunst.nix
    ./obsidian.nix

    ./misc/fonts.nix
    ./misc/input.nix
    ./misc/cursor.nix
    ./misc/gtk.nix
    ./misc/clipboard.nix
  ];

  home.packages =
    with pkgs;
    [
      jetbrains-toolbox
      flake.inputs.zen-browser.packages.${system}.default
      brightnessctl
      kdePackages.qt6ct
      nautilus
      loupe
    ]
    ++ lib.optional (lib.meta.availableOn pkgs.stdenv.hostPlatform spotify) spotify;

  home.sessionPath = [
    "$HOME/.local/share/JetBrains/Toolbox/scripts"
  ];

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

  services = {
    tailscale-systray.enable = true;
    network-manager-applet.enable = true;
    blueman-applet.enable = true;
  };
}
