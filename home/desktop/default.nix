{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:

let
  nvidiaCfg = config.my.features.nvidia;
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  imports = [
    ./niri
    ./quickshell
    ./ghostty.nix
    ./dunst.nix
    ./obsidian.nix

    ./misc/fonts.nix
    ./misc/input.nix
    ./misc/cursor.nix
    ./misc/clipboard.nix
  ];

  config = lib.mkIf config.my.features.desktop.enable {
    home.packages =
      with pkgs;
      [
        jetbrains-toolbox
        inputs.zen-browser.packages.${system}.default
        nautilus
      ]
      ++ lib.optional (lib.meta.availableOn pkgs.stdenv.hostPlatform spotify) spotify;

    # nvidia-specific environment configuration for niri
    programs.niri.settings.environment = lib.mkIf nvidiaCfg.enable {
      LIBVA_DRIVER_NAME = "nvidia";
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      __GL_VRR_ALLOWED = "1";
      NVD_BACKEND = "direct";
    };

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
  };
}
