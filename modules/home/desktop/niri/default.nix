{
  flake,
  pkgs,
  ...
}:

let
  inherit (flake.inputs.niri-float-sticky.packages.${pkgs.stdenv.hostPlatform.system})
    niri-float-sticky
    ;

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
  imports = [
    ./config/input.nix
    ./config/environments.nix
    ./config/autostarts.nix
    ./config/layout.nix
    ./config/animations.nix
    ./config/rules.nix
    ./config/effects.nix
    ./config/keybinds.nix
  ];

  home.packages = [
    floatStickyLauncher
    openGhosttyCwd
  ];

  wayland.windowManager.niri = {
    enable = true;

    # The system provides the niri session units: NixOS through programs.niri,
    # other distributions through their niri package.
    systemd.enable = false;

    settings = {
      prefer-no-csd = { };
      screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";
      cursor.xcursor-size = 20;

      debug.honor-xdg-activation-with-invalid-serial = { };
    };

    # Later configuration overrides earlier configuration, so the DMS files go last.
    # niri auto-configures monitors until DMS saves outputs.kdl.
    extraConfig = ''
      include optional=true "dms/alttab.kdl"
      include optional=true "dms/outputs.kdl"
    '';
  };
}
