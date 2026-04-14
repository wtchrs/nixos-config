{ lib, config, pkgs, ... }:

{
  config = lib.mkIf config.my.features.desktop.enable {
    home.pointerCursor = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
      size = 24;
    };
  };
}
