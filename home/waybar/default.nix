{ pkgs, ... } :

{
  home.packages = with pkgs; [
    waybar-mpris
    playerctl
  ];

  programs.waybar = {
    enable = true;
    style = builtins.readFile ./style.css;

    settings = [
      {
        layer = "top";
        margin-top = 10;
        margin-left = 20;
        margin-right = 20;
        spacing = 4;

        modules-left = [
          "custom/appmenu"
          "group/quicklinks"
          "hyprland/window"
          "mpris"
        ];

        modules-center = [
          "hyprland/workspaces"
        ];

        modules-right = [
          "group/hardware"
          "group/misc"
          "clock"
          "tray"
          "custom/exit"
        ];

        # quicklinks
        "custom/quicklink1" = {
          format = " ";
          on-click = "~/.config/waybar/scripts/terminal.sh";
          tooltip-format = "Open the terminal emulator";
        };
        "custom/quicklink2" = {
          format = " ";
          on-click = "~/.config/waybar/scripts/browser.sh";
          tooltip-format = "Open the browser";
        };
        "custom/quicklink3" = {
          format = " ";
          on-click = "~/.config/waybar/scripts/filemanager.sh";
          tooltip-format = "Open the filemanager";
        };
        "group/quicklinks" = {
          orientation = "horizontal";
          modules = [
            "custom/quicklink1"
            "custom/quicklink2"
            "custom/quicklink3"
          ];
        };

        # modules
        "hyprland/workspaces" = {
          on-click = "activate";
          active-only = false;
          all-outputs = true;
          format = "{icon}";
          format-icons = {
            "1" = "";
            "2" = "";
            "3" = "";
            "4" = "";
            "5" = "";
            "6" = "6";
            "7" = "7";
            "8" = "8";
            "9" = "9";
            "10" = "10";
            "active" = "⬤";
          };
          persistent-workspaces = { "*" = 5; };
          on-scroll-up = "hyprctl dispatch workspace e-1";
          on-scroll-down = "hyprctl dispatch workspace e+1";
        };

        "hyprland/window" = {
          rewrite = {
            "(.*) - Brave" = "$1";
            "(.*) - Chromium" = "$1";
            "(.*) - Brave Search" = "$1";
            "(.*) - Outlook" = "$1";
            "(.*) — Zen Browser" = "$1";
            "(.*) Microsoft Teams" = "$1";
          };
          separate-outputs = true;
        };

        "custom/appmenu" = {
          format = "Apps";
          tooltip-format = "Open the application launcher";
          on-click = "walker";
          tooltip = false;
        };

        "custom/exit" = {
          format = "";
          tooltip-format = "Powermenu";
          on-click = "wlogout -b 4";
        };

        "group/hardware" = {
          orientation = "inherit";
          modules = [ "cpu" "memory" "disk" ];
        };

        cpu = {
          format = "  {usage}%";
          on-click = "alacritty -e htop";
          interval = 2;
        };

        memory = {
          format = "  {}%";
          on-click = "alacritty -e htop";
          interval = 5;
        };

        disk = {
          interval = 10;
          format = "  {percentage_used}% ";
          path = "/";
          on-click = "btrfs-assistant-launcher";
        };

        "group/misc" = {
          orientation = "inherit";
          modules = [ "pulseaudio" "network" "battery" ];
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-bluetooth = "{volume}% {icon} {format_source}";
          format-bluetooth-muted = " {icon} {format_source}";
          format-muted = " {format_source}";
          format-source = "{volume}% ";
          format-source-muted = "";
          format-icons = {
            headphone = "";
            "hands-free" = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = [ "" " " " " ];
          };
          on-click = "pavucontrol";
        };

        network = {
          format = "{ifname}";
          format-wifi = " {signalStrength}%";
          format-ethernet = " {ipaddr}";
          format-disconnected = "Not connected";
          tooltip-format = " {ifname} via {gwaddri}";
          tooltip-format-wifi = " {essid} ({signalStrength}%)";
          tooltip-format-ethernet = " {ifname} ({ipaddr}/{cidr})";
          tooltip-format-disconnected = "Disconnected";
          max-length = 50;
          on-click = "alacritty -e nmtui";
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon}{capacity}%";
          format-charging = " {capacity}%";
          format-plugged = " {capacity}%";
          format-alt = "{icon} {time}";
          format-icons = [ " " " " " " " " " " ];
        };

        mpris = {
          format = "{player_icon}{title}[{position}/{length}]";
          format-paused = "{status_icon} {title}";
          player-icons.default = "▶";
          player-icons.mpv = "🎵";
          status-icons.paused = "⏸";
          interval = 1;
          max-length = 100;
        };

        tray = {
          spacing = 10;
        };

        clock = {
          tooltip-format = "<big>{:%Y %B}</big>\n<tt>{calendar}</tt>";
          format = "{:%Y-%m-%d %H:%M}";
          format-alt = "{:%Y-%m-%d}";
        };
      }
    ];
  };
}
