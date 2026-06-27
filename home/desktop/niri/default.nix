{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  inherit (inputs.niri.lib) kdl;

  inherit (inputs.niri-float-sticky.packages.${pkgs.stdenv.hostPlatform.system}) niri-float-sticky;
  floatStickyLauncher = pkgs.writeShellApplication {
    name = "niri-float-sticky-launcher";
    runtimeInputs = [ niri-float-sticky ];
    text = builtins.readFile ./scripts/niri-float-sticky-launch.sh;
  };

  openGhosttyCwd = pkgs.writeShellApplication {
    name = "niri-open-ghostty-cwd";
    runtimeInputs = [ pkgs.jq ];
    text = builtins.readFile ./scripts/niri-open-ghostty-cwd.sh;
  };
in
{
  # `programs.niri.settings.outputs` (display configuration) should be in host-specific overrides.
  # See `configurations/nixos/notebook/home/display-outputs.nix`.
  imports = [
    inputs.niri.homeModules.niri
    ./config/input.nix
    ./config/environments.nix
    ./config/autostarts.nix
    ./config/layout.nix
    ./config/animations.nix
    ./config/rules.nix
    ./config/keybinds.nix
  ];

  home.packages = [
    pkgs.xwayland-satellite
    floatStickyLauncher
    openGhosttyCwd
  ];

  programs.niri = {
    enable = true;
    package = pkgs.niri;

    settings = {
      prefer-no-csd = true;
      screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";
      cursor.size = 20;
    };

    config = lib.mkOptionDefault (
      lib.mkAfter [
        (kdl.leaf "include" "${./kdl/effects.kdl}")
      ]
    );
  };
}
