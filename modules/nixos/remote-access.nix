{ lib, ... }:

{
  systemd.services.tailscaled.serviceConfig.Environment = [
    "TS_SSH_DISABLE_FORWARDING=true"
  ];

  services = {
    tailscale = {
      enable = lib.mkDefault true;
      extraSetFlags = [
        # Use sudo to access tailscale CLI
        "--operator="
      ];
    };

    openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
    };
  };
}
