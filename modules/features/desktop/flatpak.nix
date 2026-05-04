{
  lib,
  config,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.my.features.desktop.enable {
    environment.systemPackages = with pkgs; [
      flatpak-xdg-utils
    ];

    services.flatpak.enable = true;

    systemd.services.flatpak-repo = {
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.flatpak ];
      script = ''
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
      '';
    };
  };
}
