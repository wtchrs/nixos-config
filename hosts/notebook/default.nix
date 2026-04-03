_:

{
  imports = [
    ./hardware-configuration.nix
    ./nix-ld.nix
  ];

  # Use grub
  boot.loader = {
    systemd-boot.enable = false;

    grub = {
      enable = true;
      device = "nodev";
      useOSProber = true;
      efiSupport = true;
    };

    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
  };

  # Do not change after installation.
  system.stateVersion = "25.05";
}
