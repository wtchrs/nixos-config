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
      umu-launcher
    ];

    programs = {
      steam = {
        enable = true;
        extraCompatPackages = [ cfg.proton.package ] ++ cfg.proton.extraPackages;
      };

      gamescope = {
        enable = true;
      };
    };
  };
}
