{ flake, ... }:

{
  imports = [
    flake.inputs.disko.nixosModules.disko
    ./disko.nix
    ./hardware-configuration.nix
    ./network-configuration.nix
  ];

  time.timeZone = "Asia/Tokyo";

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

  zramSwap = {
    enable = true;
    memoryPercent = 100;
    algorithm = "zstd";
    priority = 100;
  };

  services.earlyoom = {
    enable = true;
    enableNotifications = true;
  };

  # Do not change after installation.
  system.stateVersion = "26.05";
}
