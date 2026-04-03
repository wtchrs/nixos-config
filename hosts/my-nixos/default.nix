_:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Use systemd-boot
  boot.loader = {
    efi.canTouchEfiVariables = true;
    systemd-boot.enable = true;
  };

  # Do not change after installation.
  system.stateVersion = "26.05";
}
