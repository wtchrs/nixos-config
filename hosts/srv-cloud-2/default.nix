{ inputs, username, ... }:

let
  sshKeys = [
    # Remove ssh key after connecting to tailscale and enable tailscale ssh.
    # "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC/J8yX9riY/xpewtMotOCRS+4yvL3xFpSuIx2EKjZXRAO/baMBvF1xIQj+hC9nvrIIkzODqPyAxBi/rY+hymweBW+9GAWwowBd2F7dEY8oVt+L4YLLzXoQQaMLj59+S9fQL1LrVxSvf8jOfqthuiHS0WD9iI8oXWgOnSfC14hHEa1qXRcrt17C4RIMTF56wDC6dR9r/8bG/81HQwOy4475VsY3yT3xhpL2m5bvE47n3T8/KXZNIoVxDbi6BsdCabL3c/YRxgTVD2O3J8r8OzYkxpsb2QsS/SJSuLxGKmNQei3YF7J2iIU8rjdsEUUjAKi1M0VFoL7A5Cc3vSukIanv ssh-key-2026-04-29"
  ];
in
{
  imports = [
    inputs.disko.nixosModules.disko
    ./disko.nix
    ./hardware-configuration.nix
  ];

  # Use grub
  boot.loader = {
    systemd-boot.enable = false;

    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      efiInstallAsRemovable = true;
      useOSProber = false;
    };

    efi = {
      canTouchEfiVariables = false;
      efiSysMountPoint = "/boot/efi";
    };
  };

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

  networking = {
    firewall.allowedTCPPorts = [
      # Disallow ssh port after connecting to tailscale and enable tailscale ssh.
      # 22
    ];
    firewall.allowedUDPPorts = [ ];
  };

  # sudo nopassword setting
  security.sudo.wheelNeedsPassword = false;

  zramSwap.enable = true;
  zramSwap.memoryPercent = 100;

  # Do not change after installation.
  system.stateVersion = "26.05";
}
