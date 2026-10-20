{ lib, username, ... }:

{
  services = {
    tailscale = {
      enable = lib.mkDefault true;
      extraSetFlags = [
        "--operator=${username}"
      ];
    };

    openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
    };
  };
}
