{ pkgs, ... }:

{
  imports = [
    ./input.nix
    ./paperwm.nix
  ];

  home.packages = with pkgs; [
    gnome-extension-manager
    gnomeExtensions.appindicator
    gnomeExtensions.caffeine
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.vitals
    gnomeExtensions.transparent-top-bar-adjustable-transparency
    gnomeExtensions.top-bar-organizer-plus
    gnomeExtensions.advanced-media-controller
  ];

  dconf.settings = {
    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = with pkgs.gnomeExtensions; [
        appindicator.extensionUuid
        caffeine.extensionUuid
        clipboard-indicator.extensionUuid
        vitals.extensionUuid
        transparent-top-bar-adjustable-transparency.extensionUuid
        top-bar-organizer-plus.extensionUuid
        advanced-media-controller.extensionUuid
      ];
    };

    "org/gnome/shell/extensions/top-bar-organizer-plus" = {
      left-box-order = [
        "activities"
        "WorkspaceMenu"
        "FocusButton"
        "OpenPositionButton"
        "vitalsMenu"
      ];

      center-box-order = [
        "media-controls-advanced-media-controller@sanjai.com"
      ];

      right-box-order = [
        "clipboardIndicator"
        "screenRecording"
        "screenSharing"
        "dwellClick"
        "a11y"
        "keyboard"
        "dateMenu"
        "quickSettings"
      ];

      appindicator-order-mode = "safe";
    };

    "org/gnome/shell/extensions/vitals" = {
      position-in-panel = 0; # left
      use-higher-precision = true;
      show-battery = true;
      show-gpu = true;
    };

    "com/ftpix/transparentbar" = {
      transparency = 35;
    };

    "org/gnome/shell/extensions/advanced-media-controller" = {
      panel-position = "center";
      panel-index = -1;
      show-artist = true;
    };
  };
}
