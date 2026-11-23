{ pkgs, ... }:

{
  wayland.windowManager.niri.settings.binds = {
    # Shows a list of important hotkeys.
    "Mod+Shift+Slash".show-hotkey-overlay = { };

    # Wine/XWayland apps may consume the Hangul keysym before Fcitx sees it.
    "Hangul" = {
      _props.repeat = false;
      spawn = [
        "${pkgs.fcitx5}/bin/fcitx5-remote"
        "-t"
      ];
    };

    "Mod+Return" = {
      _props.hotkey-overlay-title = "Open a Terminal: ghostty";
      spawn = [ "ghostty" ];
    };

    "Mod+Shift+Return" = {
      _props.hotkey-overlay-title = "Open a Terminal in same directory: ghostty";
      spawn = [ "niri-open-ghostty-cwd" ];
    };

    "Mod+Alt+L" = {
      _props.hotkey-overlay-title = "Toggle Lock Screen";
      spawn = [
        "dms"
        "ipc"
        "lock"
        "lock"
      ];
    };

    "Mod+E" = {
      _props.hotkey-overlay-title = "Open file manager: nautilus";
      spawn = [ "nautilus" ];
    };

    "Mod+P" = {
      _props.hotkey-overlay-title = "Toggle float sticky";
      spawn = [
        "niri-float-sticky"
        "-ipc"
        "toggle_sticky"
      ];
    };

    # DMS panels
    "Mod+Space" = {
      _props.hotkey-overlay-title = "Toggle Application Launcher";
      spawn = [
        "dms"
        "ipc"
        "spotlight"
        "toggle"
      ];
    };

    "Mod+N" = {
      _props.hotkey-overlay-title = "Toggle Notification Center";
      spawn = [
        "dms"
        "ipc"
        "notifications"
        "toggle"
      ];
    };

    "Mod+X" = {
      _props.hotkey-overlay-title = "Toggle Power Menu";
      spawn = [
        "dms"
        "ipc"
        "powermenu"
        "toggle"
      ];
    };

    "Mod+M" = {
      _props.hotkey-overlay-title = "Toggle Process List";
      spawn = [
        "dms"
        "ipc"
        "processlist"
        "toggle"
      ];
    };

    "Mod+Alt+N" = {
      _props = {
        allow-when-locked = true;
        hotkey-overlay-title = "Toggle Night Mode";
      };
      spawn = [
        "dms"
        "ipc"
        "night"
        "toggle"
      ];
    };

    # volume controls and media controls
    # The allow-when-locked=true property makes them work even when the session is locked.
    "XF86AudioRaiseVolume" = {
      _props.allow-when-locked = true;
      spawn = [
        "dms"
        "ipc"
        "audio"
        "increment"
        "1"
      ];
    };

    "XF86AudioLowerVolume" = {
      _props.allow-when-locked = true;
      spawn = [
        "dms"
        "ipc"
        "audio"
        "decrement"
        "1"
      ];
    };

    "XF86AudioMute" = {
      _props.allow-when-locked = true;
      spawn = [
        "dms"
        "ipc"
        "audio"
        "mute"
      ];
    };

    "XF86AudioMicMute" = {
      _props.allow-when-locked = true;
      spawn = [
        "dms"
        "ipc"
        "audio"
        "micmute"
      ];
    };

    "XF86AudioPlay" = {
      _props.allow-when-locked = true;
      spawn = [
        "dms"
        "ipc"
        "call"
        "mpris"
        "playPause"
      ];
    };

    "XF86AudioPause" = {
      _props.allow-when-locked = true;
      spawn = [
        "dms"
        "ipc"
        "call"
        "mpris"
        "pause"
      ];
    };

    "XF86AudioNext" = {
      _props.allow-when-locked = true;
      spawn = [
        "dms"
        "ipc"
        "call"
        "mpris"
        "next"
      ];
    };

    "XF86AudioPrev" = {
      _props.allow-when-locked = true;
      spawn = [
        "dms"
        "ipc"
        "call"
        "mpris"
        "previous"
      ];
    };

    "XF86MonBrightnessUp" = {
      _props.allow-when-locked = true;
      spawn = [
        "dms"
        "ipc"
        "brightness"
        "increment"
        "1"
        ""
      ];
    };

    "XF86MonBrightnessDown" = {
      _props.allow-when-locked = true;
      spawn = [
        "dms"
        "ipc"
        "brightness"
        "decrement"
        "1"
        ""
      ];
    };

    "XF86TouchpadToggle" = {
      _props = {
        allow-when-locked = true;
        repeat = false;
      };
      spawn = [
        "niri"
        "msg"
        "action"
        "toggle-touchpad"
      ];
    };

    # Open/close the Overview
    "Mod+O" = {
      _props.repeat = false;
      toggle-overview = { };
    };

    "Mod+Q".close-window = { };

    # Move focus
    "Mod+Left".focus-column-left = { };
    "Mod+Down".focus-window-or-workspace-down = { };
    "Mod+UP".focus-window-or-workspace-up = { };
    "Mod+Right".focus-column-right = { };

    "Mod+H".focus-column-left = { };
    "Mod+J".focus-window-or-workspace-down = { };
    "Mod+K".focus-window-or-workspace-up = { };
    "Mod+L".focus-column-right = { };

    # Move window
    "Mod+Ctrl+Left".move-column-left = { };
    "Mod+Ctrl+Down".move-window-down = { };
    "Mod+Ctrl+Up".move-window-up = { };
    "Mod+Ctrl+Right".move-column-right = { };

    "Mod+Ctrl+H".move-column-left = { };
    "Mod+Ctrl+J".move-window-down-or-to-workspace-down = { };
    "Mod+Ctrl+K".move-window-up-or-to-workspace-up = { };
    "Mod+Ctrl+L".move-column-right = { };

    # Move to first and last
    "Mod+Home".focus-column-first = { };
    "Mod+End".focus-column-last = { };
    "Mod+Ctrl+Home".move-column-to-first = { };
    "Mod+Ctrl+End".move-column-to-last = { };

    # Move focus between monitors
    "Mod+Shift+Left".focus-monitor-left = { };
    "Mod+Shift+Down".focus-monitor-down = { };
    "Mod+Shift+Up".focus-monitor-up = { };
    "Mod+Shift+Right".focus-monitor-right = { };

    "Mod+Shift+H".focus-monitor-left = { };
    "Mod+Shift+J".focus-monitor-down = { };
    "Mod+Shift+K".focus-monitor-up = { };
    "Mod+Shift+L".focus-monitor-right = { };

    # Move window between monitors
    "Mod+Shift+Ctrl+Left".move-column-to-monitor-left = { };
    "Mod+Shift+Ctrl+Down".move-column-to-monitor-down = { };
    "Mod+Shift+Ctrl+Up".move-column-to-monitor-up = { };
    "Mod+Shift+Ctrl+Right".move-column-to-monitor-right = { };

    "Mod+Shift+Ctrl+H".move-column-to-monitor-left = { };
    "Mod+Shift+Ctrl+J".move-column-to-monitor-down = { };
    "Mod+Shift+Ctrl+K".move-column-to-monitor-up = { };
    "Mod+Shift+Ctrl+L".move-column-to-monitor-right = { };

    "Mod+Page_Down".focus-workspace-down = { };
    "Mod+Page_Up".focus-workspace-up = { };
    "Mod+U".focus-workspace-down = { };
    "Mod+I".focus-workspace-up = { };

    "Mod+Ctrl+Page_Down".move-column-to-workspace-down = { };
    "Mod+Ctrl+Page_Up".move-column-to-workspace-up = { };
    "Mod+Ctrl+U".move-column-to-workspace-down = { };
    "Mod+Ctrl+I".move-column-to-workspace-up = { };

    "Mod+Shift+Page_Down".move-workspace-down = { };
    "Mod+Shift+Page_Up".move-workspace-up = { };
    "Mod+Shift+U".move-workspace-down = { };
    "Mod+Shift+I".move-workspace-up = { };

    # Move workspace up/down with mouse wheel scrolling
    "Mod+WheelScrollDown" = {
      _props.cooldown-ms = 150;
      focus-workspace-down = { };
    };

    "Mod+WheelScrollUp" = {
      _props.cooldown-ms = 150;
      focus-workspace-up = { };
    };

    "Mod+Ctrl+WheelScrollDown" = {
      _props.cooldown-ms = 150;
      move-column-to-workspace-down = { };
    };

    "Mod+Ctrl+WheelScrollUp" = {
      _props.cooldown-ms = 150;
      move-column-to-workspace-up = { };
    };

    # Move column left/right with mouse wheel scrolling
    "Mod+WheelScrollRight".focus-column-right = { };
    "Mod+WheelScrollLeft".focus-column-left = { };
    "Mod+Ctrl+WheelScrollRight".move-column-right = { };
    "Mod+Ctrl+WheelScrollLeft".move-column-left = { };

    # with horizontal scrolling
    "Mod+Shift+WheelScrollDown".focus-column-right = { };
    "Mod+Shift+WheelScrollUp".focus-column-left = { };
    "Mod+Ctrl+Shift+WheelScrollDown".move-column-right = { };
    "Mod+Ctrl+Shift+WheelScrollUp".move-column-left = { };

    # Move workspace with index
    "Mod+1".focus-workspace = 1;
    "Mod+2".focus-workspace = 2;
    "Mod+3".focus-workspace = 3;
    "Mod+4".focus-workspace = 4;
    "Mod+5".focus-workspace = 5;
    "Mod+6".focus-workspace = 6;
    "Mod+7".focus-workspace = 7;
    "Mod+8".focus-workspace = 8;
    "Mod+9".focus-workspace = 9;

    "Mod+Ctrl+1".move-column-to-workspace = 1;
    "Mod+Ctrl+2".move-column-to-workspace = 2;
    "Mod+Ctrl+3".move-column-to-workspace = 3;
    "Mod+Ctrl+4".move-column-to-workspace = 4;
    "Mod+Ctrl+5".move-column-to-workspace = 5;
    "Mod+Ctrl+6".move-column-to-workspace = 6;
    "Mod+Ctrl+7".move-column-to-workspace = 7;
    "Mod+Ctrl+8".move-column-to-workspace = 8;
    "Mod+Ctrl+9".move-column-to-workspace = 9;

    # Consume or expel focused window
    "Mod+BracketLeft".consume-or-expel-window-left = { };
    "Mod+BracketRight".consume-or-expel-window-right = { };

    # Consume one window from the right to the bottom of the focused column.
    "Mod+Comma".consume-window-into-column = { };

    # Expel the bottom window from the focused column to the right.
    "Mod+Period".expel-window-from-column = { };

    # Adjust width/height of the focused column/window
    "Mod+R".switch-preset-column-width = { };
    "Mod+Shift+R".switch-preset-window-height = { };
    "Mod+Ctrl+R".reset-window-height = { };
    "Mod+F".maximize-column = { };
    "Mod+Shift+F".fullscreen-window = { };
    "Mod+Ctrl+F".expand-column-to-available-width = { };
    "Mod+C".center-column = { };
    "Mod+Ctrl+C".center-visible-columns = { };

    # Finer width adjustments
    "Mod+Minus".set-column-width = "-10%";
    "Mod+Equal".set-column-width = "+10%";

    # Finer height adjustments when in column with other windows.
    "Mod+Shift+Minus".set-window-height = "-10%";
    "Mod+Shift+Equal".set-window-height = "+10%";

    # Move the focused window between the floating and the tiling layout.
    "Mod+V" = {
      _props.hotkey-overlay-title = "Toggle floating";
      toggle-window-floating = { };
    };

    "Mod+Shift+V" = {
      _props.hotkey-overlay-title = "Switch focus between floating and tiling";
      switch-focus-between-floating-and-tiling = { };
    };

    # Toggle tabbed column display mode.
    "Mod+W".toggle-column-tabbed-display = { };

    # Screenshots
    "Mod+Shift+S".spawn = [
      "dms"
      "screenshot"
    ];
    "Print".spawn = [
      "dms"
      "screenshot"
    ];
    "Ctrl+Print".spawn = [
      "dms"
      "screenshot"
      "full"
    ];
    "Alt+Print".spawn = [
      "dms"
      "screenshot"
      "window"
    ];

    # Escape hatch for inhibitor
    "Mod+Escape" = {
      _props.allow-inhibiting = false;
      toggle-keyboard-shortcuts-inhibit = { };
    };

    # Quit / power
    "Mod+Shift+E".spawn = [
      "dms"
      "ipc"
      "call"
      "powermenu"
      "toggle"
    ];
    "Ctrl+Alt+Delete".spawn = [
      "dms"
      "ipc"
      "call"
      "powermenu"
      "toggle"
    ];
    "Mod+Shift+P".spawn = [
      "dms"
      "ipc"
      "call"
      "lock"
      "lockAndOutputsOff"
    ];
  };
}
