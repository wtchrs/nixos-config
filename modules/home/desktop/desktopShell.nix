{ flake, ... }:

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

      clockFormat = "24h";
      dockTransparency = 0.65;
      cornerRadius = 12;
      windSpeedUnit = "ms";
      springBounce = 0;
      animationVariant = 2;
      blurEnabled = false;
      controlCenterShowMicPercent = true;

      # Button layout is declarative; toggle state stays in session.json.
      controlCenterWidgets = [
        {
          id = "volumeSlider";
          enabled = true;
          width = 50;
        }
        {
          id = "brightnessSlider";
          enabled = true;
          width = 50;
        }
        {
          id = "wifi";
          enabled = true;
          width = 50;
        }
        {
          id = "bluetooth";
          enabled = true;
          width = 50;
        }
        {
          id = "audioOutput";
          enabled = true;
          width = 50;
        }
        {
          id = "audioInput";
          enabled = true;
          width = 50;
        }
        {
          id = "nightMode";
          enabled = true;
          width = 25;
        }
        {
          id = "darkMode";
          enabled = true;
          width = 25;
        }
        {
          id = "doNotDisturb";
          enabled = true;
          width = 25;
        }
        {
          id = "idleInhibitor";
          enabled = true;
          width = 25;
        }
      ];

      showOccupiedWorkspacesOnly = true;
      workspaceFocusedBorderEnabled = true;
      mediaUseAlbumArtAccent = true;
      audioWheelScrollAmount = 1;
      appIdSubstitutions = [ ];
      launcherStyle = "island";
      syncModeWithPortal = false;
      # Delegate lock-screen authentication to the system's PAM policy.
      lockPamExternallyManaged = true;
      lockBeforeSuspend = true;

      # Idle timeouts are measured in seconds; zero disables automatic suspend.
      batteryLockTimeout = 5 * 60;
      batteryMonitorTimeout = 10 * 60;
      batterySuspendTimeout = 15 * 60;
      acLockTimeout = 20 * 60;
      acMonitorTimeout = 30 * 60;
      acSuspendTimeout = 0;

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
            {
              id = "focusedWindow";
              focusedWindowSize = 0; # Small
            }
            "runningApps"
            "workspaceSwitcher"
            "launcherButton"
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
          widgetTransparency = 1;

          island = true;
          islandInteractionMode = "click";
          islandCompactThickness = 36;
          islandHomeCompactTight = false;
          islandSatellitePosition = "island";
          islandSatelliteSwoopRadius = 12;
          islandSatelliteTransparency = 0.65;
          islandSatelliteGap = 32;
          islandTransparency = 1;
          islandHighContrast = false;
        }
      ];
    };

    niri = {
      enableKeybinds = true;
      includes = {
        enable = true;
        # Keep static keybinds; only these DMS-managed fragments are included.
        filesToInclude = [
          "alttab"
          "outputs"
        ];
      };
    };
  };
}
