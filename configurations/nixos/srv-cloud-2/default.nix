{ inputs, ... }:

let
  username = "wtchrs";
  hostName = "srv-cloud-2";
in
{
  imports = [
    (import ../../../modules { inherit inputs; })
    ../../../users/${username}/system.nix

    inputs.disko.nixosModules.disko
    ./disko.nix
    ./hardware-configuration.nix
    ./network-configuration.nix
  ];

  _module.args = {
    inherit inputs username hostName;
  };

  nixpkgs.hostPlatform = "aarch64-linux";
  networking.hostName = hostName;

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

  home-manager.users.${username}.imports = [
    ../../../home/core
    ../../../users/${username}/home.nix
    (_: {
      home = {
        inherit username;
        homeDirectory = "/home/${username}";
        stateVersion = "26.05";
      };
    })
  ];
}
