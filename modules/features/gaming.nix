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
  options.my.features.gaming.enable = lib.mkEnableOption "Gaming setup";

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
