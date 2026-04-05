{
  lib,
  pkgs,
  inputs,
  ...
}:

let
  inherit (inputs.niri.lib) kdl;

  open-ghostty-cwd-script = builtins.readFile ./scripts/niri-open-ghostty-cwd.sh;
  open-ghostty-cwd-bin = pkgs.writeShellScriptBin "niri-open-ghostty-cwd" open-ghostty-cwd-script;
in
{
  home.packages = [
    pkgs.xwayland-satellite
    open-ghostty-cwd-bin
  ];

  # Disabled nix configurations to use raw niri configurations.
  imports = [
    inputs.niri.homeModules.niri
    ./config/input.nix
    ./config/outputs.nix
    ./config/environments.nix
    ./config/autostarts.nix
    ./config/layout.nix
    ./config/animations.nix
    ./config/rules.nix
    ./config/keybinds.nix
  ];

  programs.niri = {
    enable = true;
    package = pkgs.niri-unstable;

    settings = {
      prefer-no-csd = true;
      screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";
    };

    # niri-flake does not provide blur options in settings yet.
    #
    # Original KDL for blur:
    # blur {
    #   passes 4
    #   offset 4.0
    #   noise 0.02
    #   saturation 1.7
    # }
    #
    # layer-rule {
    #   match namespace="^quickshell:(bar|tray-menu)$"
    #   background-effect { blur true xray false }
    # }
    #
    # layer-rule {
    #   match namespace="^quickshell:launcher$"
    #   background-effect { blur true xray true }
    # }
    #
    # window-rule {
    #   match app-id="com.mitchellh.ghostty"
    #   background-effect { blur true xray false }
    # }

    config = lib.mkOptionDefault (
      lib.mkAfter [
        (kdl.node "blur"
          [ ]
          [
            (kdl.leaf "passes" 4)
            (kdl.leaf "offset" 4.0)
            (kdl.leaf "noise" 0.02)
            (kdl.leaf "saturation" 1.7)
          ]
        )

        (kdl.node "layer-rule"
          [ ]
          [
            (kdl.leaf "match" { namespace = "^quickshell:(bar|tray-menu)$"; })
            (kdl.node "background-effect"
              [ ]
              [
                (kdl.leaf "blur" true)
                (kdl.leaf "xray" false)
              ]
            )
          ]
        )

        (kdl.node "layer-rule"
          [ ]
          [
            (kdl.leaf "match" { namespace = "^quickshell:launcher$"; })
            (kdl.node "background-effect"
              [ ]
              [
                (kdl.leaf "blur" true)
                (kdl.leaf "xray" true)
              ]
            )
          ]
        )

        (kdl.node "window-rule"
          [ ]
          [
            (kdl.leaf "match" { app-id = "^com.mitchellh.ghostty$"; })
            (kdl.node "background-effect"
              [ ]
              [
                (kdl.leaf "blur" true)
                (kdl.leaf "xray" false)
              ]
            )
          ]
        )
      ]
    );
  };
}
