{ lib, pkgs, ... }:

let
  openGhosttyCwd = pkgs.writeShellApplication {
    name = "hyprland-open-ghostty-cwd";
    runtimeInputs = [
      pkgs.jq
      pkgs.procps
      pkgs.coreutils
      pkgs.hyprland
      pkgs.ghostty
    ];
    text = builtins.readFile ./scripts/open-ghostty-cwd.sh;
  };
in
{
  imports = [ ./keybinds.nix ];

  home.packages = [
    openGhosttyCwd
    pkgs.rofi
    pkgs.hyprshot
    pkgs.swaybg
    pkgs.swaylock
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    # Explicitly use the legacy format supported by the pinned Hyprland 0.56.
    configType = "hyprlang";
    systemd.enable = true;
    systemd.variables = [ "XDG_SESSION_DESKTOP" ];

    settings = {
      # Override individual outputs in host-specific display configuration.
      monitor = [ ",preferred,auto,1" ];

      env = [
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "TERMINAL,ghostty"
        "EDITOR,nvim"
        "QT_QPA_PLATFORM,wayland;xcb"
        "QT_QPA_PLATFORMTHEME,qt6ct"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        "SDL_VIDEODRIVER,wayland"
        "MOZ_ENABLE_WAYLAND,1"
        "OZONE_PLATFORM,wayland"
        "ELECTRON_OZONE_PLATFORM_HINT,auto"
        "XCURSOR_SIZE,20"
        "HYPRCURSOR_SIZE,20"
      ];

      # Dunst, Fcitx and the polkit agent follow graphical-session.target.
      exec-once = [
        "${lib.getExe pkgs.swaybg} -i ~/Pictures/wallpapers/wallpaper -m fill"
        "${lib.getExe pkgs.vesktop}"
      ]
      ++ lib.optional (lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.spotify) "NIXOS_OZONE_WL=1 ${lib.getExe pkgs.spotify} --ozone-platform=wayland";

      input = {
        kb_layout = "us";
        kb_options = "ctrl:nocaps,korean:ralt_hangul,korean:rctrl_hanja";
        repeat_delay = 250;
        follow_mouse = 1;
        touchpad = {
          natural_scroll = true;
          tap-to-click = true;
          tap_button_map = "lrm";
          drag_lock = true;
          disable_while_typing = true;
        };
      };

      general = {
        gaps_in = 5;
        gaps_out = 20;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        layout = "dwindle";
        resize_on_border = true;
      };

      dwindle.preserve_split = true;

      decoration = {
        rounding = 4;
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
        };
        shadow = {
          enabled = true;
          range = 5;
          render_power = 2;
          color = "rgba(1a1a1aee)";
        };
      };

      animations = {
        enabled = true;
        bezier = [ "overshoot,0.05,0.9,0.1,1.05" ];
        animation = [
          "windows,1,6,overshoot,popin 80%"
          "windowsOut,1,6,default,popin 80%"
          "border,1,10,default"
          "borderangle,1,8,default"
          "fade,1,6,default"
          "workspaces,1,4,overshoot,slidevert"
          "layersIn,1,4,overshoot,slide"
          "layersOut,1,4,default,slide"
        ];
      };

      gesture = [ "3,vertical,workspace" ];

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
      };

      xwayland.force_zero_scaling = true;

      workspace = [ "s[true],gapsout:50" ];

      layerrule = [
        "no_anim on, match:namespace ^selection$"
        "no_anim on, match:namespace ^hyprpicker$"
      ];

      windowrule = [
        "float on, match:class ^(float)$"
        "float on, match:class .*-float.*"
        "float on, size 800 500, match:initial_title ^(Yazi|terminal filechooser)$"
        "float on, pin on, match:title ^(Picture-in-Picture)$"
        "workspace special:chat silent, match:class ^(discord|vesktop)$"
        "workspace special:music silent, match:class ^(spotify)$"
      ];
    };
  };

  # Also applies to the standalone Home Manager desktop profile.
  xdg.portal.config.Hyprland.default = [
    "gnome"
    "gtk"
  ];
}
