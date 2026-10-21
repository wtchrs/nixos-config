{ lib, ... }:

{
  services = {
    tlp.enable = true;
    power-profiles-daemon.enable = false;
  };

  systemd = {
    # Keep systemd's rfkill state store/restore enabled despite the TLP module masking it
    services.systemd-rfkill.enable = lib.mkForce true;
    sockets.systemd-rfkill.enable = lib.mkForce true;
  };
}
