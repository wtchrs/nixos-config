{
  lib,
  config,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.my.features.desktop.enable {
    environment.systemPackages = with pkgs; [
      nautilus
    ];

    services.gvfs.enable = true;

    programs.nautilus-open-any-terminal = {
      enable = true;
      terminal = "ghostty";
    };
  };
}
