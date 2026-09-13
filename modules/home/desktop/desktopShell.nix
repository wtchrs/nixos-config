{ flake, lib, ... }:

{
  imports = [
    flake.inputs.dms.homeModules.dank-material-shell
    flake.inputs.dms.homeModules.niri
  ];

  programs.dank-material-shell = {
    enable = true;
    systemd.enable = true;

    settings = {
      # Prevent legacy migrations from changing defaults in this sparse config.
      configVersion = 18;

      dockTransparency = 0.65;
      cornerRadius = 12;
      windSpeedUnit = "ms";
      springBounce = 0;
      animationVariant = 2;
      blurEnabled = true;
      controlCenterShowMicPercent = true;
      showOccupiedWorkspacesOnly = true;
      workspaceFocusedBorderEnabled = true;
      mediaUseAlbumArtAccent = true;
      audioWheelScrollAmount = 1;
      appIdSubstitutions = [ ];
      launcherStyle = "island";
      syncModeWithPortal = false;

      dockOpenOnOverview = true;
      dockSpacing = 8;
      dockBottomGap = -8;
      dockMargin = 8;
      dockIndicatorStyle = "line";
      dockLauncherEnabled = true;
      dockShowTrash = true;

      notificationCompactMode = true;
      osdAlwaysShowValue = true;
      osdMediaPlaybackEnabled = true;
      osdPowerProfileEnabled = true;

      # Bar arrays replace the default configuration rather than merging with it.
      barConfigs = [
        {
          id = "default";
          name = "Main Bar";
          enabled = true;
          position = 0;
          screenPreferences = [ "all" ];
          showOnLastDisplay = true;
          leftWidgets = [
            "launcherButton"
            "workspaceSwitcher"
            "runningApps"
            "focusedWindow"
          ];
          centerWidgets = [
            "music"
            "clock"
            "weather"
          ];
          rightWidgets = [
            "systemTray"
            "clipboard"
            {
              id = "cpuUsage";
              enabled = false;
            }
            {
              id = "memUsage";
              enabled = false;
            }
            "notificationButton"
            "battery"
            "controlCenterButton"
          ];
          widgetTransparency = 0.65;

          island = true;
          islandHomeCompactTight = true;
          islandNotificationExpand = true;
          islandSatelliteSwoopRadius = 12;
          islandSatelliteTransparency = 0.65;
          islandSatelliteGap = 32;
          islandTransparency = 0.85;
          islandHighContrast = false;
        }
      ];
    };

    niri = {
      enableKeybinds = true;
      includes.enable = false;
    };
  };

  programs.niri.settings.layout.struts.top = lib.mkForce (-10);
}
