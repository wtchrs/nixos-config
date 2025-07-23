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

  services.hyprpaper = {
    enable = true;
    settings = {
      splash = false;
      preload = [
        "~/Pictures/wallpapers/wallpaper.jpg"
      ];
      wallpaper = [
        ",~/Pictures/wallpapers/wallpaper.jpg"
      ];
    };
  };

  # services.hyprpolkitagent.enable = true;

  xdg.portal = {
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    config.common.default = "gtk";
  };

  wayland.windowManager.hyprland = {
    enable = true;

    settings  = {
      exec-once = [
        "waybar"
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
