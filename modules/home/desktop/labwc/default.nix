{
  lib,
  pkgs,
  ...
}:

let
  screenshot = pkgs.writeShellApplication {
    name = "labwc-screenshot";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.grim
      pkgs.slurp
    ];
    text = builtins.readFile ./scripts/screenshot.sh;
  };

  action = key: name: {
    "@key" = key;
    action."@name" = name;
  };

  actionWith = key: name: attributes: {
    "@key" = key;
    action = {
      "@name" = name;
    }
    // lib.mapAttrs' (name': value: lib.nameValuePair "@${name'}" value) attributes;
  };

  execute = key: command: actionWith key "Execute" { inherit command; };

  executeWhenLocked =
    key: command:
    (execute key command)
    // {
      "@allowWhenLocked" = "yes";
    };
in
{
  home.packages = [
    screenshot
    pkgs.swaybg
    pkgs.swaylock
    pkgs.wlopm
  ];

  wayland.windowManager.labwc = {
    enable = true;

    environment = [
      "XKB_DEFAULT_LAYOUT=us"
      "XKB_DEFAULT_OPTIONS=ctrl:nocaps,korean:ralt_hangul,korean:rctrl_hanja"
    ];

    autostart = [
      "${lib.getExe pkgs.wlr-randr} --output eDP-1 --scale 1.25"
      "${lib.getExe pkgs.swaybg} -i ~/Pictures/wallpapers/wallpaper -m fill >/dev/null 2>&1 &"
      "${lib.getExe pkgs.vesktop} &"
    ]
    ++ lib.optional (lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.spotify) "NIXOS_OZONE_WL=1 ${lib.getExe pkgs.spotify} --ozone-platform=wayland &";

    systemd.variables = [
      "DISPLAY"
      "WAYLAND_DISPLAY"
      "XDG_CURRENT_DESKTOP"
      "XDG_SESSION_DESKTOP"
      "XDG_SESSION_TYPE"
    ];

    rc = {
      core = {
        decoration = "server";
        gap = 10;
      };

      placement.policy = "center";

      theme = {
        name = "Niri";
        icon = "Adwaita";
        titlebar = {
          layout = "icon:iconify,max,close";
          showTitle = "yes";
        };
        cornerRadius = 4;
        keepBorder = "yes";
        maximizedDecoration = "none";
        dropShadows = "yes";
        dropShadowsOnTiled = "yes";
        font = {
          name = "Sarasa Mono K";
          size = 10;
        };
      };

      windowSwitcher = {
        "@preview" = "yes";
        "@outlines" = "yes";
        "@unshade" = "yes";
        osd = {
          "@show" = "yes";
          "@style" = "thumbnail";
          "@output" = "all";
          "@thumbnailLabelFormat" = "%T";
        };
        fields.field = [
          {
            "@content" = "icon";
            "@width" = "15%";
          }
          {
            "@content" = "desktop_entry_name";
            "@width" = "30%";
          }
          {
            "@content" = "title";
            "@width" = "55%";
          }
        ];
      };

      focus = {
        followMouse = "no";
        followMouseRequiresMovement = "no";
        raiseOnFocus = "no";
      };

      snapping = {
        range = {
          "@inner" = 10;
          "@outer" = 10;
        };
        cornerRange = 50;
        overlay = {
          "@enabled" = "yes";
          delay = {
            "@inner" = 150;
            "@outer" = 150;
          };
        };
        topMaximize = "yes";
        notifyClient = "always";
      };

      desktops = {
        "@number" = 9;
        "@popupTime" = 600;
        "@prefix" = "Workspace";
      };

      regions.region = [
        {
          "@name" = "center-third";
          "@x" = "33.333%";
          "@y" = "0%";
          "@width" = "33.334%";
          "@height" = "100%";
        }
        {
          "@name" = "center-half";
          "@x" = "25%";
          "@y" = "0%";
          "@width" = "50%";
          "@height" = "100%";
        }
        {
          "@name" = "center-three-quarter";
          "@x" = "12.5%";
          "@y" = "0%";
          "@width" = "75%";
          "@height" = "100%";
        }
        {
          "@name" = "full";
          "@x" = "0%";
          "@y" = "0%";
          "@width" = "100%";
          "@height" = "100%";
        }
      ];

      keyboard = {
        repeatRate = 25;
        repeatDelay = 250;
        keybind = [
          (execute "Hangul" "fcitx5-remote -t")
          (execute "W-Return" "ghostty")
          (execute "W-S-Return" "ghostty")
          (execute "W-A-l" "swaylock")
          (execute "W-e" "nautilus")
          (action "W-p" "ToggleOmnipresent")

          (executeWhenLocked "XF86AudioRaiseVolume" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.01+")
          (executeWhenLocked "XF86AudioLowerVolume" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.01-")
          (executeWhenLocked "XF86AudioMute" "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
          (executeWhenLocked "XF86AudioMicMute" "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")
          (executeWhenLocked "XF86AudioPlay" "playerctl play-pause")
          (executeWhenLocked "XF86AudioPause" "playerctl play-pause")
          (executeWhenLocked "XF86AudioNext" "playerctl next")
          (executeWhenLocked "XF86AudioPrev" "playerctl previous")
          (executeWhenLocked "XF86MonBrightnessUp" "brightnessctl set 1%+")
          (executeWhenLocked "XF86MonBrightnessDown" "brightnessctl set 1%-")

          (action "A-Tab" "NextWindow")
          (action "A-S-Tab" "PreviousWindow")
          {
            "@key" = "W-o";
            action = {
              "@name" = "ShowMenu";
              "@menu" = "client-list-combined-menu";
              position = {
                x = "center";
                y = "center";
              };
            };
          }
          (action "W-q" "Close")

          (action "W-Left" "PreviousWindowImmediate")
          (action "W-h" "PreviousWindowImmediate")
          (action "W-Up" "PreviousWindowImmediate")
          (action "W-k" "PreviousWindowImmediate")
          (action "W-Right" "NextWindowImmediate")
          (action "W-l" "NextWindowImmediate")
          (action "W-Down" "NextWindowImmediate")
          (action "W-j" "NextWindowImmediate")

          (actionWith "W-C-Left" "MoveToEdge" { direction = "left"; })
          (actionWith "W-C-h" "MoveToEdge" { direction = "left"; })
          (actionWith "W-C-Down" "MoveToEdge" { direction = "down"; })
          (actionWith "W-C-j" "MoveToEdge" { direction = "down"; })
          (actionWith "W-C-Up" "MoveToEdge" { direction = "up"; })
          (actionWith "W-C-k" "MoveToEdge" { direction = "up"; })
          (actionWith "W-C-Right" "MoveToEdge" { direction = "right"; })
          (actionWith "W-C-l" "MoveToEdge" { direction = "right"; })

          (actionWith "W-S-Left" "FocusOutput" { direction = "left"; })
          (actionWith "W-S-h" "FocusOutput" { direction = "left"; })
          (actionWith "W-S-Down" "FocusOutput" { direction = "down"; })
          (actionWith "W-S-j" "FocusOutput" { direction = "down"; })
          (actionWith "W-S-Up" "FocusOutput" { direction = "up"; })
          (actionWith "W-S-k" "FocusOutput" { direction = "up"; })
          (actionWith "W-S-Right" "FocusOutput" { direction = "right"; })
          (actionWith "W-S-l" "FocusOutput" { direction = "right"; })

          (actionWith "W-C-S-Left" "MoveToOutput" { direction = "left"; })
          (actionWith "W-C-S-h" "MoveToOutput" { direction = "left"; })
          (actionWith "W-C-S-Down" "MoveToOutput" { direction = "down"; })
          (actionWith "W-C-S-j" "MoveToOutput" { direction = "down"; })
          (actionWith "W-C-S-Up" "MoveToOutput" { direction = "up"; })
          (actionWith "W-C-S-k" "MoveToOutput" { direction = "up"; })
          (actionWith "W-C-S-Right" "MoveToOutput" { direction = "right"; })
          (actionWith "W-C-S-l" "MoveToOutput" { direction = "right"; })

          (actionWith "W-Page_Down" "GoToDesktop" { to = "right"; })
          (actionWith "W-u" "GoToDesktop" { to = "right"; })
          (actionWith "W-Page_Up" "GoToDesktop" { to = "left"; })
          (actionWith "W-i" "GoToDesktop" { to = "left"; })
          (actionWith "W-C-Page_Down" "SendToDesktop" {
            to = "right";
            follow = "yes";
          })
          (actionWith "W-C-u" "SendToDesktop" {
            to = "right";
            follow = "yes";
          })
          (actionWith "W-C-Page_Up" "SendToDesktop" {
            to = "left";
            follow = "yes";
          })
          (actionWith "W-C-i" "SendToDesktop" {
            to = "left";
            follow = "yes";
          })
        ]
        ++ map (desktop: actionWith "W-${toString desktop}" "GoToDesktop" { to = toString desktop; }) (
          lib.range 1 9
        )
        ++ map (
          desktop:
          actionWith "W-C-${toString desktop}" "SendToDesktop" {
            to = toString desktop;
            follow = "yes";
          }
        ) (lib.range 1 9)
        ++ [
          (actionWith "W-r" "ToggleSnapToRegion" { region = "center-half"; })
          (actionWith "W-S-r" "ToggleSnapToRegion" { region = "center-three-quarter"; })
          (actionWith "W-C-r" "ToggleSnapToRegion" { region = "center-third"; })
          (action "W-f" "ToggleMaximize")
          (action "W-S-f" "ToggleFullscreen")
          (actionWith "W-C-f" "ToggleSnapToRegion" { region = "full"; })
          (actionWith "W-c" "ToggleSnapToRegion" { region = "center-half"; })
          (actionWith "W-Minus" "ResizeRelative" {
            left = "-5%";
            right = "-5%";
          })
          (actionWith "W-Equal" "ResizeRelative" {
            left = "5%";
            right = "5%";
          })
          (actionWith "W-S-Minus" "ResizeRelative" {
            top = "-5%";
            bottom = "-5%";
          })
          (actionWith "W-S-Equal" "ResizeRelative" {
            top = "5%";
            bottom = "5%";
          })

          (execute "W-S-s" "labwc-screenshot area")
          (execute "Print" "labwc-screenshot area")
          (execute "C-Print" "labwc-screenshot screen")
          (execute "A-Print" "labwc-screenshot area")

          {
            "@key" = "W-Escape";
            "@overrideInhibition" = "yes";
            action."@name" = "ToggleKeybinds";
          }
          (action "W-S-e" "Exit")
          (action "C-A-Delete" "Exit")
          (execute "W-S-p" "wlopm --off '*'")
        ];
      };

      mouse.default = true;

      libinput.device = {
        "@category" = "touchpad";
        naturalScroll = "yes";
        tap = "yes";
        tapButtonMap = "lrm";
        tapAndDrag = "yes";
        dragLock = "yes";
        disableWhileTyping = "yes";
      };
    };
  };

  xdg.configFile."labwc/shutdown".source = pkgs.writeShellScript "labwc-shutdown" ''
    ${lib.getExe' pkgs.systemd "systemctl"} --user stop graphical-session.target
  '';

  xdg.dataFile."themes/Niri/labwc/themerc".source = ./themerc;
}
