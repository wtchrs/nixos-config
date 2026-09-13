{ lib, pkgs, ... }:

let
  directions = {
    H = "l";
    Left = "l";
    J = "d";
    Down = "d";
    K = "u";
    Up = "u";
    L = "r";
    Right = "r";
  };
  workspaces = {
    U = "+1";
    Page_Down = "+1";
    I = "-1";
    Page_Up = "-1";
    mouse_down = "+1";
    mouse_up = "-1";
  };
  screenshot =
    mode: "exec, ${lib.getExe pkgs.hyprshot} -m ${mode} --freeze -o \"$HOME/Pictures/Screenshots\"";
in
{
  wayland.windowManager.hyprland.settings = {
    bind = [
      ", Hangul, exec, ${pkgs.fcitx5}/bin/fcitx5-remote -t"
      "SUPER, Return, exec, ghostty"
      "SUPER SHIFT, Return, exec, hyprland-open-ghostty-cwd"
      "SUPER ALT, L, exec, swaylock"
      "SUPER, E, exec, nautilus"
      "SUPER, Space, exec, ${lib.getExe pkgs.rofi} -show drun"
      "SUPER, Q, killactive"
      "SUPER, V, togglefloating"
      "SUPER, P, pin"
      "SUPER, F, fullscreen, 1"
      "SUPER SHIFT, F, fullscreen, 0"
      "SUPER, C, centerwindow"
      "SUPER, W, togglegroup"
      "SUPER, Tab, cyclenext"
      "SUPER CTRL, P, pseudo"
      "SUPER SHIFT, semicolon, layoutmsg, togglesplit"
      "SUPER, grave, togglespecialworkspace"
      "SUPER SHIFT, grave, movetoworkspace, special"
      "SUPER, D, togglespecialworkspace, chat"
      "SUPER SHIFT, D, movetoworkspace, special:chat"
      "SUPER, M, togglespecialworkspace, music"
      "SUPER SHIFT, M, movetoworkspace, special:music"
      "SUPER SHIFT, S, ${screenshot "region"}"
      ", Print, ${screenshot "region"}"
      "CTRL, Print, ${screenshot "output"}"
      "ALT, Print, ${screenshot "window"}"
      "SUPER SHIFT, E, exit"
      "CTRL ALT, Delete, exit"
      "SUPER SHIFT, P, dpms, off"
    ]
    ++ lib.concatLists (
      lib.mapAttrsToList (key: direction: [
        "SUPER, ${key}, movefocus, ${direction}"
        "SUPER CTRL, ${key}, movewindow, ${direction}"
        "SUPER SHIFT, ${key}, focusmonitor, ${direction}"
        "SUPER CTRL SHIFT, ${key}, movewindow, mon:${direction}"
      ]) directions
    )
    ++ lib.concatLists (
      lib.mapAttrsToList (key: offset: [
        "SUPER, ${key}, workspace, r${offset}"
        "SUPER CTRL, ${key}, movetoworkspace, r${offset}"
      ]) workspaces
    )
    ++ lib.concatMap (
      index:
      let
        key = toString index;
      in
      [
        "SUPER, ${key}, workspace, ${key}"
        "SUPER CTRL, ${key}, movetoworkspace, ${key}"
      ]
    ) (lib.range 1 9);

    binde = [
      "SUPER, minus, resizeactive, -10% 0"
      "SUPER, equal, resizeactive, 10% 0"
      "SUPER SHIFT, minus, resizeactive, 0 -10%"
      "SUPER SHIFT, equal, resizeactive, 0 10%"
    ];
    bindl = [
      ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ", XF86AudioPlay, exec, playerctl play-pause"
      ", XF86AudioPause, exec, playerctl play-pause"
      ", XF86AudioNext, exec, playerctl next"
      ", XF86AudioPrev, exec, playerctl previous"
    ];
    bindel = [
      ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.01+"
      ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.01-"
      ", XF86MonBrightnessUp, exec, brightnessctl set 1%+"
      ", XF86MonBrightnessDown, exec, brightnessctl set 1%-"
    ];
    bindm = [
      "SUPER, mouse:272, movewindow"
      "SUPER, mouse:273, resizewindow"
    ];
  };
}
