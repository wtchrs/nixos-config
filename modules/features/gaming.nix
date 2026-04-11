{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.my.features.gaming;
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      mangohud
      gamemode
    ];

    programs.steam = {
      enable = true;
      extraCompatPackages = with pkgs; [ proton-ge-bin ];
    };
  };
}
