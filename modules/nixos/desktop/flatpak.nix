{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    flatpak-xdg-utils
  ];

  services.flatpak.enable = true;

  systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    path = [
      pkgs.flatpak
      pkgs.gnugrep
    ];

    serviceConfig = {
      Type = "oneshot";
      Restart = "on-failure";
      RestartSec = "1min";
    };

    script = ''
      flatpak remotes --system --columns=name | grep -qx flathub \
        || flatpak remote-add --system flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    '';
  };
}
