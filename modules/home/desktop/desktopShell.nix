{ flake, ... }:

let
  lockScreenWidgets = [
    {
      id = "lock_clock";
      widgetType = "desktopClock";
      enabled = true;
      config = {
        displayPreferences = [ "all" ];
        syncPositionAcrossScreens = true;
        style = "expressive";
        transparency = 0;
        weight = 0;
        twoTone = false;
        showDate = true;
        showDigitalSeconds = false;
        showAnalogNumbers = false;
        showAnalogSeconds = true;
        autoPosition = false;
        colorMode = "default";
        customColor = "#ffffff";
      };
    }
    {
      id = "lock_auth";
      widgetType = "lockAuth";
      enabled = true;
      config = {
        displayPreferences = [ "all" ];
        syncPositionAcrossScreens = true;
        style = "expressive";
        profileVisibility = "always";
        passwordVisibility = "always";
      };
    }
    {
      id = "lock_notifications";
      widgetType = "lockNotifications";
      enabled = true;
      config = {
        displayPreferences = [ "all" ];
        syncPositionAcrossScreens = true;
        mode = 2;
      };
    }
    {
      id = "lock_status";
      widgetType = "lockStatus";
      enabled = true;
      config = {
        displayPreferences = [ "all" ];
        syncPositionAcrossScreens = true;
        showMediaPlayer = true;
        showWeather = true;
        background = false;
      };
    }
    {
      id = "lock_power";
      widgetType = "lockPower";
      enabled = false;
      config = {
        displayPreferences = [ "all" ];
        syncPositionAcrossScreens = true;
        shape = "round";
      };
    }
  ];
in
{
  imports = [
    flake.inputs.dms.homeModules.dank-material-shell
    flake.inputs.dms.homeModules.niri
  ];

  programs.dank-material-shell = {
    enable = true;
    systemd.enable = true;
    enableCalendarEvents = false;

    settings = {
      # Prevent legacy migrations from changing defaults in this sparse config.
      configVersion = 42;

      clockFormat = "24h";
      radiusStrength = 38;
      windSpeedUnit = "ms";

      controlCenterWidgets = [
        {
          id = "user";
          enabled = true;
          w = 4;
          h = 1;
          col = 0;
          row = 0;
        }
        {
          id = "settings";
          enabled = true;
          w = 1;
          h = 1;
          small = true;
          col = 5;
          row = 0;
        }
        {
          id = "lock";
          enabled = true;
          w = 1;
          h = 1;
          small = true;
          col = 6;
          row = 0;
        }
        {
          id = "power";
          enabled = true;
          w = 1;
          h = 1;
          small = true;
          col = 7;
          row = 0;
        }
        {
          id = "volumeSlider";
          enabled = true;
          w = 4;
          h = 1;
          col = 0;
          row = 1;
        }
        {
          id = "brightnessSlider";
          enabled = true;
          w = 4;
          h = 1;
          col = 4;
          row = 1;
        }
        {
          id = "wifi";
          enabled = true;
          w = 4;
          h = 1;
          col = 0;
          row = 2;
        }
        {
          id = "bluetooth";
          enabled = true;
          w = 4;
          h = 1;
          col = 4;
          row = 2;
        }
        {
          id = "audioOutput";
          enabled = true;
          w = 4;
          h = 1;
          col = 0;
          row = 3;
        }
        {
          id = "audioInput";
          enabled = true;
          w = 4;
          h = 1;
          col = 4;
          row = 3;
        }
        {
          id = "nightMode";
          enabled = true;
          w = 2;
          h = 1;
          col = 0;
          row = 4;
          small = true;
        }
        {
          id = "darkMode";
          enabled = true;
          w = 2;
          h = 1;
          col = 2;
          row = 4;
          small = true;
        }
        {
          id = "doNotDisturb";
          enabled = true;
          w = 2;
          h = 1;
          col = 4;
          row = 4;
          small = true;
        }
        {
          id = "idleInhibitor";
          enabled = true;
          w = 2;
          h = 1;
          col = 6;
          row = 4;
          small = true;
        }
        {
          id = "edit";
          enabled = true;
          w = 1;
          h = 1;
          small = true;
          col = 4;
          row = 0;
        }
        {
          id = "runningApps";
          enabled = true;
          w = 4;
          h = 1;
          small = true;
          col = 0;
          row = 5;
        }
        {
          id = "builtin_tailscale";
          enabled = true;
          w = 4;
          h = 1;
          col = 4;
          row = 5;
          small = true;
        }
      ];

      dashCards = [
        {
          id = "clock";
          w = 2;
          h = 1;
          col = 0;
          row = 0;
        }
        {
          id = "weather";
          w = 1;
          h = 1;
          col = 2;
          row = 0;
        }
        {
          id = "notifications";
          w = 3;
          h = 4;
          col = 0;
          row = 1;
        }
        {
          id = "calendar";
          w = 3;
          h = 3;
          col = 3;
          row = 0;
        }
        {
          id = "media";
          w = 3;
          h = 2;
          col = 3;
          row = 3;
        }
      ];

      dashOptions.overview.panelRows = 4;
      audioWheelScrollAmount = 1;
      appIdSubstitutions = [ ];
      launcherStyle = "island";
      syncModeWithPortal = false;

      # Delegate lock-screen and greeter authentication to the system's PAM policy.
      lockPamExternallyManaged = true;
      greeterPamExternallyManaged = true;

      lockBeforeSuspend = true;

      lockScreenWidgetInstances = lockScreenWidgets;
      greeterWidgetInstances =
        builtins.filter (widget: widget.widgetType != "lockNotifications") lockScreenWidgets
        ++ [
          {
            id = "greeter_session";
            widgetType = "greeterSession";
            enabled = true;
            config = {
              displayPreferences = [ "all" ];
              syncPositionAcrossScreens = true;
            };
          }
        ];

      # Idle timeouts are measured in seconds.
      batteryLockTimeout = 5 * 60;
      batteryMonitorTimeout = 10 * 60;
      batterySuspendTimeout = 15 * 60;
      acLockTimeout = 20 * 60;
      acMonitorTimeout = 30 * 60;

      dockConfigs = [
        {
          id = "dock";
          name = "Dock";
          openOnOverview = true;
          iconSize = 40;
          itemSpacing = 4;
          bottomGap = -8;
          followInterfaceStyle = false;
          transparency = 0.65;
          indicatorStyle = "line";
          launcherLogoMode = "apps";
          showTrash = true;
        }
      ];

      notificationCompactMode = true;
      osdAlwaysShowValue = true;
      osdMediaPlaybackEnabled = true;
      osdPowerProfileEnabled = true;

      # Bar arrays replace the default configuration rather than merging with it.
      barConfigs =
        let
          workspaceSwitcher = {
            id = "workspaceSwitcher";
            workspaceFocusedBorderEnabled = true;
            workspaceIndicatorStyle = "dots";
            workspaceIndicatorCompact = true;
          };
          mainBar = {
            id = "default";
            name = "Main Bar";
            enabled = true;
            position = 0;
            screenPreferences = [ "all" ];
            showOnLastDisplay = true;
            openOnOverview = true;
            leftWidgets = [
              "launcherButton"
              workspaceSwitcher
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
              "notificationButton"
              "cpuUsage"
              "memUsage"
              "battery"
              {
                id = "controlCenterButton";
                showMicPercent = true;
              }
            ];
            noBackground = true;

            island = true;
            islandInteractionMode = "click";
            islandCompactThickness = 36;
            gothCornerRadiusOverride = true;
            islandSatelliteFollowInterfaceStyle = false;
            islandSatelliteTransparency = 0.65;
            islandSatelliteGap = 32;
            islandHomeLayout = [
              {
                id = "media";
                enabled = true;
              }
              {
                id = "clock";
                enabled = true;
              }
              {
                id = "notifications";
                enabled = true;
              }
              {
                id = "privacy";
                enabled = true;
              }
              {
                id = "workspaces";
                enabled = false;
              }
              {
                id = "tray";
                enabled = false;
              }
              {
                id = "weather";
                enabled = false;
              }
              {
                id = "status";
                enabled = false;
              }
              {
                id = "volume";
                enabled = false;
              }
              {
                id = "brightness";
                enabled = false;
              }
            ];
          };
        in
        [
          mainBar
          (
            mainBar
            // {
              id = "dot1793004804558";
              name = "Dot";
              enabled = false;
              island = false;
              dot = true;
              followInterfaceStyle = false;
              leftWidgets = [
                "launcherButton"
                workspaceSwitcher
                "focusedWindow"
                "runningApps"
              ];
            }
          )
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
