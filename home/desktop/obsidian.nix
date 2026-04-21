{ lib, config, ... }:

{
  config = lib.mkIf config.my.features.desktop.enable {
    programs.obsidian.enable = true;
  };
}
