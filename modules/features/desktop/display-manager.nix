{
  lib,
  config,
  pkgs,
  ...
}:

let
  sddmKwinConfig = pkgs.writeTextDir "kwinrc" ''
    [Plugins]
    shakecursorEnabled=false
  '';
in
{
  config = lib.mkIf config.my.features.desktop.enable {
    environment.systemPackages = with pkgs; [
      sddm-astronaut
      bibata-cursors
    ];

    services.displayManager = {
      sessionPackages = [
        pkgs.niri-unstable
      ];

      sddm = {
        enable = true;
        package = pkgs.kdePackages.sddm;

        wayland = {
          enable = true;
          compositor = "kwin";
          compositorCommand = "${lib.getExe' pkgs.coreutils "env"} XDG_CONFIG_HOME=${sddmKwinConfig} ${lib.getExe' pkgs.kdePackages.kwin "kwin_wayland"} --no-global-shortcuts --no-kactivities --no-lockscreen --locale1";
        };

        theme = "sddm-astronaut-theme";

        settings = {
          Theme = {
            CursorTheme = "Bibata-Modern-Ice";
            CursorSize = "24";
          };
        };

        extraPackages = with pkgs; [
          kdePackages.qtsvg
          kdePackages.qtmultimedia
          kdePackages.qtvirtualkeyboard
        ];
      };
    };
  };
}
