{
  pkgs,
  lib,
  username,
  ...
}:

{
  imports = [
    ./desktop-manager.nix
    ./portal.nix
    ./file-manager.nix
    ./flatpak.nix
    ./keyring.nix
    ./input-method.nix
  ];

  environment.systemPackages = with pkgs; [
    glib.bin
  ];

  services = {
    seatd = {
      enable = true;
      user = username;
    };

    tumbler.enable = true;
    upower.enable = true;
    playerctld.enable = true;

    pipewire = {
      enable = true;
      pulse.enable = true;
    };
  };

  security = {
    # policy kit
    polkit.enable = true;

    # GTK4-based polkit authentication agent
    soteria.enable = true;

    # Asign limited real-time scheduling priorities to time-sensitive processes like audio
    rtkit.enable = true;
  };

  systemd.user.services.polkit-soteria = {
    wants = lib.mkForce [ ];
    partOf = [ "graphical-session.target" ];
  };
}
