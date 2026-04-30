{ inputs, ... }:

{
  imports = [
    inputs.disko.nixosModules.disko
    ./disko.nix
    ./hardware-configuration.nix
    ./network-configuration.nix
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

  zramSwap.enable = true;
  zramSwap.memoryPercent = 100;

  # Do not change after installation.
  system.stateVersion = "26.05";
}
