_:

{
  imports = [
    ./animations.nix
    ./binds.nix
    ./decorations.nix
    ./environments.nix
    ./general.nix
    ./input.nix
  ];

  home.file.".config/hypr/scripts" = {
    source = ./scripts;
    recursive = true;
    executable = true;
  };

  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
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

      windowrulev2 = let
        pipTitle = "Picture-in-Picture";
      in [
        "float,title:${pipTitle}"
        "pin,title:${pipTitle}"
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
  };
}
