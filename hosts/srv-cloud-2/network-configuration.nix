{ config, username, ... }:

let
  sshKeys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNSB2sAJnby+yoTViZDqz37AWP736lzitRtkNoGlFHJPAFuFya/SA3t+zXiuGMUm23Hz4gah30bpKdHvG+fB3tnLwWPT0CXqvsaa2/W7S4geDBoQAfnVlxceATMQhjo57T+ewAdbOkqgaje7tftLcjHFTBGfzjo/dl9GXDUJe+TZ7JdQ1mYrv+HssGYKfrF5i66iEkMuetGHaOJ0jghnyScWrGmXTCiV3ZkM/gJV1twVB8Pok1yMB1NmjD4Izsh0mA1nVt36XxRMImrrmpH4oX+UMCWx+tvvNJPgtVHQKBL5+m3x/Qq8QhwlNp17u0aUa6Pr7Pqh6JB6K4ghDYKJq9 ssh-key-2026-05-15"
  ];
in
{
  # Enable ssh root login
  services.openssh.settings.PermitRootLogin = "prohibit-password";
  # Set user sshkeys and disable password
  users.users = {
    root = {
      openssh.authorizedKeys.keys = sshKeys;
      hashedPassword = "!";
    };
    ${username} = {
      openssh.authorizedKeys.keys = sshKeys;
      hashedPassword = "!";
    };
  };

  services.tailscale = {
    enable = true;
    # Enables routing features for tailscale, including sysctl/kernel parameters
    # normally configured via `/etc/sysctl.d/*`, such as:
    #   net.ipv4.ip_forward = 1
    #   net.ipv6.conf.all.forwarding = 1
    useRoutingFeatures = "server";
  };

  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    allowedTCPPorts = [
      22
    ];
    allowedUDPPorts = [
      config.services.tailscale.port
    ];
  };

  # sudo nopassword setting
  security.sudo.wheelNeedsPassword = false;
}
