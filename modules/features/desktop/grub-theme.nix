{ lib, config, ... }:

{
  config = lib.mkIf config.my.features.desktop.enable {
    boot.loader.grub2-theme = {
      enable = true;
      theme = "stylish";
      footer = true;
      customResolution = "1920x1080";
    };
  };
}
