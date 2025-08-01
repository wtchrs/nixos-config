{ ... } :

{
  wayland.windowManager.hyprland.settings = {
    "$mod" = "SUPER";

    bind = [
      "$mod, RETURN, exec, alacritty"
      "$mod, Q, killactive"
      "$mod, E, exec, thunar" # Open the filemanager
      "$mod, T, togglefloating"
      "$mod, F, fullscreen"
      "$mod, SPACE, exec, rofi -show drun"
      "$mod, P, pin"
      "$mod CTRL, P, pseudo"
      "$mod SHIFT, code:47, togglesplit" # semicolon
      "$mod SHIFT, B, exec, ~/.config/hypr/scripts/reload-waybar.sh" # Reload Waybar
      "$mod SHIFT, W, exec, ~/.config/hypr/scripts/reload-hyprpaper.sh" # Reload hyprpaper after a changing the wallpaper
      "$mod SHIFT, S, exec, hyprshot -m output -o ~/Pictures/screenshots" # Screenshot
      ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 1%+"
      ", XF86AudioLowerVolume, exec, wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 1%-"
      ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
      ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
      ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ", XF86WLAN, exec, nmcli radio wifi toggle"
      ", XF86Refresh, exec, xdotool key F5"

      # Switch workspaces with $mod + [0-9]
      "$mod, 1, workspace, 1"
      "$mod, 2, workspace, 2"
      "$mod, 3, workspace, 3"
      "$mod, 4, workspace, 4"
      "$mod, 5, workspace, 5"
      "$mod, 6, workspace, 6"
      "$mod, 7, workspace, 7"
      "$mod, 8, workspace, 8"
      "$mod, 9, workspace, 9"
      "$mod, 0, workspace, 10"

      # Move active window to a workspace with $mod + SHIFT + [0-9]
      "$mod SHIFT, 1, movetoworkspace, 1"
      "$mod SHIFT, 2, movetoworkspace, 2"
      "$mod SHIFT, 3, movetoworkspace, 3"
      "$mod SHIFT, 4, movetoworkspace, 4"
      "$mod SHIFT, 5, movetoworkspace, 5"
      "$mod SHIFT, 6, movetoworkspace, 6"
      "$mod SHIFT, 7, movetoworkspace, 7"
      "$mod SHIFT, 8, movetoworkspace, 8"
      "$mod SHIFT, 9, movetoworkspace, 9"
      "$mod SHIFT, 0, movetoworkspace, 10"

      # Scroll through existing workspaces with $mod + scroll
      "$mod, mouse_down, workspace, e+1"
      "$mod, mouse_up, workspace, e-1"

      # Move focus with $mod + arrow keys
      "$mod, left,  movefocus, l"
      "$mod, right, movefocus, r"
      "$mod, up,    movefocus, u"
      "$mod, down,  movefocus, d"
      "$mod, H, movefocus, l"
      "$mod, L, movefocus, r"
      "$mod, K, movefocus, u"
      "$mod, J, movefocus, d"
      # Move window with $mod + SHIFT + arrow keys
      "$mod SHIFT, left,  movewindow, l"
      "$mod SHIFT, right, movewindow, r"
      "$mod SHIFT, up,    movewindow, u"
      "$mod SHIFT, down,  movewindow, d"
      "$mod SHIFT, H, movewindow, l"
      "$mod SHIFT, L, movewindow, r"
      "$mod SHIFT, K, movewindow, u"
      "$mod SHIFT, J, movewindow, d"
    ];

    bindm = [
      # Move/resize windows with mainMod + LMB/RMB and dragging
      "$mod, mouse:272, movewindow"
      "$mod, mouse:273, resizewindow"
    ];

    binde = [
      # Resize window with $mod + CTRL + arrow keys
      "$mod CTRL, left,  resizeactive, -10   0"
      "$mod CTRL, right, resizeactive,  10   0"
      "$mod CTRL, up,    resizeactive,   0 -10"
      "$mod CTRL, down,  resizeactive,   0  10"
      "$mod CTRL, H, resizeactive, -10   0"
      "$mod CTRL, L, resizeactive,  10   0"
      "$mod CTRL, K, resizeactive,   0 -10"
      "$mod CTRL, J, resizeactive,   0  10"
    ];
  };
}
