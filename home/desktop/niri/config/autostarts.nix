{ lib, config, ... }:

{
  config = lib.mkIf config.my.features.desktop.enable {
    programs.niri.settings.spawn-at-startup = [
      { argv = [ "qs" ]; }
      { argv = [ "dunst" ]; }
      {
        argv = [
          "systemctl"
          "--user"
          "start"
          "hyprpolkitagent"
        ];
      }
      { argv = [ "vesktop" ]; }
      { argv = [ "spotify" ]; }
    ];
  };
}
