{
  flake,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./niri
    ./labwc
    ./desktopShell.nix
    ./ghostty.nix
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
      # D-Bus prompt service for pinentry-gnome3 outside GNOME.
      gcr_3

      # Control brightness
      brightnessctl

      # Control wlroots
      wlrctl

      # Set theme for QT apps
      kdePackages.qt6ct

      # Manage JetBrains IDEs
      jetbrains-toolbox

      # browser
      flake.inputs.zen-browser.packages.${stdenv.hostPlatform.system}.default
      chromium

      # file manager
      nautilus

      # file sharing
      # Open TCP/UDP port 53317 if you can't receive files
      localsend

      # image viewer
      loupe

      # video player
      celluloid

      # screenshot
      grim
      slurp

      # efficient learning using flashcards
      anki

      # CLI music player
      cliamp
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
    gpg-agent.pinentry.package = pkgs.pinentry-gnome3;
    tailscale-systray.enable = true;
  };
}
