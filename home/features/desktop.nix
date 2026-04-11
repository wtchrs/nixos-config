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
    ../niri
    ../quickshell
    ../programs/ghostty.nix
    ../programs/dunst.nix
    ../misc/fonts.nix
    ../misc/input.nix
    ../misc/cursor.nix
  ];

  home.packages =
    with pkgs;
    [
      jetbrains-toolbox
      inputs.zen-browser.packages.${system}.default
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
}
