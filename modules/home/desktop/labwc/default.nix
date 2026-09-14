{
  lib,
  pkgs,
  ...
}:

let
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
  wayland.windowManager.labwc = {
    enable = true;

    environment = [
      "QT_QPA_PLATFORM=wayland"
      "XKB_DEFAULT_LAYOUT=us"
      "XKB_DEFAULT_OPTIONS=ctrl:nocaps,korean:ralt_hangul,korean:rctrl_hanja"
    ];

    autostart = [
      "${lib.getExe pkgs.wlr-randr} --output eDP-1 --scale 1.25"
      "${lib.getExe pkgs.vesktop} &"
    ]
    ++ lib.optional (lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.spotify) "NIXOS_OZONE_WL=1 ${lib.getExe pkgs.spotify} --ozone-platform=wayland &";

    systemd.variables = [
      "QT_QPA_PLATFORM"
      "LABWC_PID"
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
        "@popupTime" = 0;
        "@prefix" = "Workspace";
      };

      regions.region = [
        {
          "@name" = "center-half";
          "@x" = "25%";
          "@y" = "0%";
          "@width" = "50%";
          "@height" = "100%";
        }
      ];

      keyboard = {
        repeatRate = 25;
        repeatDelay = 250;
        keybind = [
          (execute "Hangul" "fcitx5-remote -t")
          (execute "W-Return" "ghostty")
          (execute "W-space" "dms ipc call spotlight toggle")
          (execute "W-v" "dms ipc call clipboard toggle")
          (execute "W-comma" "dms ipc call settings focusOrToggle")
          (execute "W-n" "dms ipc call notifications toggle")
          (execute "W-A-l" "dms ipc call lock lock")
          (execute "W-e" "nautilus")
          (action "W-p" "ToggleOmnipresent")

          (executeWhenLocked "XF86AudioRaiseVolume" "dms ipc call audio increment 1")
          (executeWhenLocked "XF86AudioLowerVolume" "dms ipc call audio decrement 1")
          (executeWhenLocked "XF86AudioMute" "dms ipc call audio mute")
          (executeWhenLocked "XF86AudioMicMute" "dms ipc call audio micmute")
          (executeWhenLocked "XF86AudioPlay" "dms ipc call mpris playPause")
          (executeWhenLocked "XF86AudioPause" "dms ipc call mpris playPause")
          (executeWhenLocked "XF86AudioNext" "dms ipc call mpris next")
          (executeWhenLocked "XF86AudioPrev" "dms ipc call mpris previous")
          (executeWhenLocked "XF86MonBrightnessUp" "dms ipc call brightness increment 1 \"\"")
          (executeWhenLocked "XF86MonBrightnessDown" "dms ipc call brightness decrement 1 \"\"")

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

          (actionWith "W-Left" "ToggleSnapToEdge" {
            direction = "left";
            combine = "yes";
          })
          (actionWith "W-h" "ToggleSnapToEdge" {
            direction = "left";
            combine = "yes";
          })
          (actionWith "W-Down" "ToggleSnapToEdge" {
            direction = "down";
            combine = "yes";
          })
          (actionWith "W-j" "ToggleSnapToEdge" {
            direction = "down";
            combine = "yes";
          })
          (actionWith "W-Up" "ToggleSnapToEdge" {
            direction = "up";
            combine = "yes";
          })
          (actionWith "W-k" "ToggleSnapToEdge" {
            direction = "up";
            combine = "yes";
          })
          (actionWith "W-Right" "ToggleSnapToEdge" {
            direction = "right";
            combine = "yes";
          })
          (actionWith "W-l" "ToggleSnapToEdge" {
            direction = "right";
            combine = "yes";
          })

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

          (actionWith "W-Page_Down" "GoToDesktop" {
            to = "right";
            wrap = "no";
          })
          (actionWith "W-u" "GoToDesktop" {
            to = "right";
            wrap = "no";
          })
          (actionWith "W-Page_Up" "GoToDesktop" {
            to = "left";
            wrap = "no";
          })
          (actionWith "W-i" "GoToDesktop" {
            to = "left";
            wrap = "no";
          })
          (actionWith "W-C-Page_Down" "SendToDesktop" {
            to = "right";
            follow = "yes";
            wrap = "no";
          })
          (actionWith "W-C-u" "SendToDesktop" {
            to = "right";
            follow = "yes";
            wrap = "no";
          })
          (actionWith "W-C-Page_Up" "SendToDesktop" {
            to = "left";
            follow = "yes";
            wrap = "no";
          })
          (actionWith "W-C-i" "SendToDesktop" {
            to = "left";
            follow = "yes";
            wrap = "no";
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
          (actionWith "W-S-r" "ToggleMaximize" { direction = "vertical"; })
          (action "W-C-r" "UnSnap")
          (action "W-f" "ToggleMaximize")
          (action "W-S-f" "ToggleFullscreen")
          (actionWith "W-C-f" "ToggleMaximize" { direction = "horizontal"; })
          (actionWith "W-c" "AutoPlace" { policy = "center"; })
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

          (execute "W-S-s" "dms screenshot")

          {
            "@key" = "W-Escape";
            "@overrideInhibition" = "yes";
            action."@name" = "ToggleKeybinds";
          }
          (execute "W-S-e" "dms ipc call powermenu toggle")
          (execute "C-A-Delete" "dms ipc call powermenu toggle")
          (execute "W-S-p" "dms ipc call lock lockAndOutputsOff")
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

  xdg = {
    configFile."labwc/shutdown".source = pkgs.writeShellScript "labwc-shutdown" ''
      ${lib.getExe' pkgs.systemd "systemctl"} --user stop graphical-session.target
    '';

    # Keep the root menu aligned with the most useful niri/labwc keybindings.
    # This is written as XML because Home Manager's labwc menu generator cannot
    # express action attributes such as direction, combine, or region.
    configFile."labwc/menu.xml".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <openbox_menu>
        <menu id="root-menu" label="">
          <item label="_Applications  [Super+Space]" icon="applications-other">
            <action name="Execute" command="dms ipc call spotlight toggle" />
          </item>
          <item label="_Settings  [Super+,]">
            <action name="Execute" command="dms ipc call settings focusOrToggle" />
          </item>

          <separator />

          <menu id="windows-menu" label="_Windows">
            <!--
              Built-in dynamic menus must be referenced by id only. Adding a
              label makes labwc parse these as new, empty inline menus.
            -->
            <menu id="client-list-combined-menu" />
            <menu id="client-send-to-menu" />
            <separator />
            <item label="Show on _all workspaces  [Super+P]">
              <action name="ToggleOmnipresent" />
            </item>
            <item label="_Close  [Super+Q]">
              <action name="Close" />
            </item>
          </menu>

          <menu id="layout-menu" label="_Layout">
            <item label="Snap _left  [Super+Left]">
              <action name="ToggleSnapToEdge" direction="left" combine="yes" />
            </item>
            <item label="Snap _right  [Super+Right]">
              <action name="ToggleSnapToEdge" direction="right" combine="yes" />
            </item>
            <item label="Snap _up  [Super+Up]">
              <action name="ToggleSnapToEdge" direction="up" combine="yes" />
            </item>
            <item label="Snap _down  [Super+Down]">
              <action name="ToggleSnapToEdge" direction="down" combine="yes" />
            </item>
            <separator />
            <item label="Center _half  [Super+R]">
              <action name="ToggleSnapToRegion" region="center-half" />
            </item>
            <item label="_Center  [Super+C]">
              <action name="AutoPlace" policy="center" />
            </item>
            <item label="_Maximize  [Super+F]">
              <action name="ToggleMaximize" />
            </item>
            <item label="_Fullscreen  [Super+Shift+F]">
              <action name="ToggleFullscreen" />
            </item>
            <item label="_Restore  [Super+Ctrl+R]">
              <action name="UnSnap" />
            </item>
          </menu>

          <item label="_Capture region  [Super+Shift+S]">
            <action name="Execute" command="dms screenshot" />
          </item>

          <separator />

          <item label="Disable compositor _shortcuts  [Super+Escape]">
            <action name="ToggleKeybinds" />
          </item>
          <item label="_Lock  [Super+Alt+L]">
            <action name="Execute" command="dms ipc call lock lock" />
          </item>
          <item label="Lock and turn displays _off  [Super+Shift+P]">
            <action name="Execute" command="dms ipc call lock lockAndOutputsOff" />
          </item>

          <item label="_Reconfigure">
            <action name="Reconfigure" />
          </item>

          <item label="_Power menu  [Super+Shift+E]">
            <action name="Execute" command="dms ipc call powermenu toggle" />
          </item>
        </menu>
      </openbox_menu>
    '';

    dataFile."themes/Niri/labwc/themerc".source = ./themerc;
  };
}
