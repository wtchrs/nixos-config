{ pkgs, ... } :

{
  imports = [
    ./animations.nix
    ./binds.nix
    ./decorations.nix
    ./environments.nix
    ./general.nix
    ./input.nix
  ];

  # link all files in `./scripts` to `~/.config/i3/scripts`
  home.file.".config/hypr/scripts" = {
    source = ./scripts;
    recursive = true;
    executable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-hyprland ];
  };

  wayland.windowManager.hyprland = {
    enable = true;

    settings  = {
      exec-once = [
        # "waybar"
        # "hyprpaper"
        # "dunst"
        # "systemctl --user start hyprpolkitagent"
      ];

      gestures = {
        workspace_swipe = true;
      };

      layerrule = [
        "blur, rofi"
        "noanim, hyprpicker"
        "noanim, selection"
      ];

      dwindle = {
        pseudotile = true; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
        preserve_split = true; # you probably want this
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
      };

      xwayland = {
        force_zero_scaling = true;
      };
    };

    extraConfig = ''
      monitor = ,1920x1080,auto,1.2
    '';
  };
}
