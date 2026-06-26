{ inputs, ... }:

let
  username = "wtchrs";
  hostName = "notebook-nixos";
in
{
  imports = [
    (import ../../../modules { inherit inputs; })
    ../../../users/${username}/system.nix

    inputs.grub2-themes.nixosModules.default
    ../../../modules/features/desktop/grub-theme.nix

    ./hardware-configuration.nix
    ./system/kernel.nix
    ./system/gpu.nix
    ./system/nix-ld.nix
  ];

  _module.args = {
    inherit inputs username hostName;
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = hostName;

  my.features = {
    desktop = {
      enable = true;
      displayManager.enable = true;
    };
    nvidia.enable = true;
    gaming.enable = true;
  };

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

  time.hardwareClockInLocalTime = true;

  networking = {
    networkmanager.enable = true;
    firewall.allowedTCPPorts = [ ];
    firewall.allowedUDPPorts = [ ];
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
    ../../../home
    ../../../users/${username}/home.nix
    (_: {
      home = {
        inherit username;
        homeDirectory = "/home/${username}";
        stateVersion = "26.05";
      };
    })
    {
      my.features = {
        desktop.enable = true;
        nvidia.enable = true;
        gaming.enable = true;
      };
    }
    ./home/display-outputs.nix
  ];
}
