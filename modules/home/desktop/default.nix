{
  flake,
  lib,
  pkgs,
  ...
}:

let
  inherit (pkgs.stdenv.hostPlatform) system;

  zenUnwrapped = flake.inputs.zen-browser.packages.${system}.zen-browser-unwrapped;

  zenFixed =
    pkgs.wrapFirefox
      (zenUnwrapped.overrideAttrs (old: {
        passthru = (old.passthru or { }) // {
          # Changed attrname from ffmpegSupport to withFFmpeg
          withFFmpeg = true;
        };
      }))
      {
        pname = "zen-browser";
      };
in
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
      # Control brightness
      brightnessctl

      # Control wlroots
      wlrctl

      # Set theme for QT apps
      kdePackages.qt6ct

      # Manage JetBrains IDEs
      jetbrains-toolbox

      # browser
      #flake.inputs.zen-browser.packages.${system}.default
      zenFixed

      # file manager
      nautilus

      # image viewer
      loupe

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
    tailscale-systray.enable = true;
    network-manager-applet.enable = true;
    blueman-applet.enable = true;
  };
}
