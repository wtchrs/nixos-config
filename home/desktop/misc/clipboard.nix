{ lib, config, pkgs, ... }:

{
  config = lib.mkIf config.my.features.desktop.enable {
    home.packages = [ pkgs.wl-clipboard ];
    services.cliphist.enable = true;
  };
}
