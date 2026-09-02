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
    ./labwc
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
      # Control brightness
      brightnessctl

      # Control wlroots
      wlrctl

      # Set theme for QT apps
      kdePackages.qt6ct

      # Manage JetBrains IDEs
      jetbrains-toolbox

      # browser
      flake.inputs.zen-browser.packages.${system}.default

      # file manager
      nautilus

      # image viewer
      loupe

      # screenshot
      grim
      slurp

      # efficient learning using flashcards
      anki
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
