{ lib, config, pkgs, ... }:

{
  config = lib.mkIf config.my.features.desktop.enable {
    home.pointerCursor = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
      size = 20;
    };
  };
}
