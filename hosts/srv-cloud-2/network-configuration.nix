{ config, lib, username, ... }:

let
  sshKeys = [
    # Remove ssh key after connecting to tailscale and enable tailscale ssh.
    # "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC/J8yX9riY/xpewtMotOCRS+4yvL3xFpSuIx2EKjZXRAO/baMBvF1xIQj+hC9nvrIIkzODqPyAxBi/rY+hymweBW+9GAWwowBd2F7dEY8oVt+L4YLLzXoQQaMLj59+S9fQL1LrVxSvf8jOfqthuiHS0WD9iI8oXWgOnSfC14hHEa1qXRcrt17C4RIMTF56wDC6dR9r/8bG/81HQwOy4475VsY3yT3xhpL2m5bvE47n3T8/KXZNIoVxDbi6BsdCabL3c/YRxgTVD2O3J8r8OzYkxpsb2QsS/SJSuLxGKmNQei3YF7J2iIU8rjdsEUUjAKi1M0VFoL7A5Cc3vSukIanv ssh-key-2026-04-29"
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
    enable = lib.mkDefault true;
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
      # Disallow ssh port after connecting to tailscale and enable tailscale ssh.
      # 22
    ];
    allowedUDPPorts = [
      config.services.tailscale.port
    ];
  };

  # sudo nopassword setting
  security.sudo.wheelNeedsPassword = false;
}
