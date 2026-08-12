{ pkgs, ... }:

{
  home.packages = with pkgs.gnomeExtensions; [
    paperwm
  ];

  dconf.settings = {
    "org/gnome/shell" = {
      enabled-extensions = with pkgs.gnomeExtensions; [
        paperwm.extensionUuid
      ];
    };

    "org/gnome/shell/extensions/paperwm" = {
      default-focus-mode = 1; # center
      only-scratch-in-overview = true;
      selection-border-radius-bottom = 12;
      selection-border-size = 2;
      show-window-position-bar = false;
      show-workspace-indicator = false;
    };

    "org/gnome/shell/extensions/paperwm/keybindings" = {
      switch-left = [
        "<Super>Left"
        "<Super>h"
      ];
      switch-right = [
        "<Super>Right"
        "<Super>l"
      ];
      switch-up = [
        "<Super>Up"
        "<Super>k"
      ];
      switch-down = [
        "<Super>Down"
        "<Super>j"
      ];

      move-left = [
        "<Control><Super>Left"
        "<Control><Super>h"
      ];
      move-right = [
        "<Control><Super>Right"
        "<Control><Super>l"
      ];
      move-up = [
        "<Control><Super>Up"
        "<Control><Super>k"
      ];
      move-down = [
        "<Control><Super>Down"
        "<Control><Super>j"
      ];

      switch-first = [ "<Super>Home" ];
      switch-last = [ "<Super>End" ];

      switch-up-workspace = [
        "<Super>Page_Up"
        "<Super>i"
      ];
      switch-down-workspace = [
        "<Super>Page_Down"
        "<Super>u"
      ];
      move-up-workspace = [
        "<Control><Super>Page_Up"
        "<Control><Super>i"
      ];
      move-down-workspace = [
        "<Control><Super>Page_Down"
        "<Control><Super>u"
      ];

      switch-monitor-left = [
        "<Shift><Super>Left"
        "<Shift><Super>h"
      ];
      switch-monitor-right = [
        "<Shift><Super>Right"
        "<Shift><Super>l"
      ];
      switch-monitor-above = [
        "<Shift><Super>Up"
        "<Shift><Super>k"
      ];
      switch-monitor-below = [
        "<Shift><Super>Down"
        "<Shift><Super>j"
      ];

      move-monitor-left = [
        "<Control><Shift><Super>Left"
        "<Control><Shift><Super>h"
      ];
      move-monitor-right = [
        "<Control><Shift><Super>Right"
        "<Control><Shift><Super>l"
      ];
      move-monitor-above = [
        "<Control><Shift><Super>Up"
        "<Control><Shift><Super>k"
      ];
      move-monitor-below = [
        "<Control><Shift><Super>Down"
        "<Control><Shift><Super>j"
      ];

      slurp-in = [ "<Super>comma" ];
      barf-out = [ "<Super>period" ];

      cycle-width = [ "<Super>r" ];
      cycle-height = [ "<Shift><Super>r" ];
      resize-w-dec = [ "<Super>minus" ];
      resize-w-inc = [ "<Super>equal" ];
      resize-h-dec = [ "<Shift><Super>minus" ];
      resize-h-inc = [ "<Shift><Super>equal" ];

      toggle-maximize-width = [ "<Super>f" ];
      paper-toggle-fullscreen = [ "<Shift><Super>f" ];
      center-horizontally = [ "<Super>c" ];
      close-window = [ "<Super>q" ];
    };
  };

  xdg.configFile."paperwm/user.css".text = ''
    .paperwm-selection {
      background-color: transparent;
      background-image: none;
      box-shadow: none;
      border: 5px solid #33ccffee;
    }
  '';
}
