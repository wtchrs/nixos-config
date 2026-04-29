{ inputs, username, ... }:

let
  sshKeys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7QGgYMN2OU7Kzfhd4hhkhfdT56nqf83YFdVur4kaLs6+dNGnK1mIIuk5g/M+7aSeUyTYhSz7vGSKsJtEpxoKDxRSNZAYF91jr9FNuA5tl9z4KpWv2e0X7ziLAU4GAwVmy6SvI3gz34Lu4lmm1DIGXv55oJNHGC4yRV+TobvI2L08RujU3shVzrW0J81yhFu/BPtP9caYlfF4E2Q1dNfqHoG5y+KI8gKF9nCljlf0XTHKwfH7QoR/PdzwVILHaiCtBZqKGUrZqPvTiOG7RbaLcvbbs4VPOEWjaC71wuJfJ9S1Mym2HuM0lDl5sdV28uzU7DRpJJ4ORvG1mtojlwbTl ssh-key-2026-04-29"
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
      efiSysMountPoint = "/boot";
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
    firewall.allowedTCPPorts = [ 22 ];
    firewall.allowedUDPPorts = [ ];
  };

  # sudo nopassword setting
  security.sudo.wheelNeedsPassword = false;

  zramSwap.enable = true;
  zramSwap.memoryPercent = 100;

  # Do not change after installation.
  system.stateVersion = "26.05";
}
