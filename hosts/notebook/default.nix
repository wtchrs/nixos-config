_:

{
  imports = [
    ./nvidia.nix
    ./hardware-configuration.nix
    ./nix-ld.nix
  ];

  home-manager.sharedModules = [ ./home.nix ];

  # Use systemd-boot
  boot.loader = {
    efi.canTouchEfiVariables = true;
    systemd-boot.enable = true;
  };

  # Do not change after installation.
  system.stateVersion = "25.05";
}
