{ flake, ... }:

let
  inherit (flake) inputs self;
  username = "wtchrs";
  hostName = "srv-cloud-2";
in
{
  imports = [
    self.nixosModules.default
    ({ pkgs, ... }: {
      users.users.${username} = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "docker"
          "networkmanager"
          "video"
          "input"
          "render"
        ];
        shell = pkgs.zsh;
      };
    })

    inputs.disko.nixosModules.disko
    ./disko.nix
    ./hardware-configuration.nix
    ./network-configuration.nix
  ];

  _module.args = {
    inherit username hostName;
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
    self.homeModules.core
    self.homeModules.identity-git-gpg
    (_: {
      _module.args = {
        inherit username hostName;
      };

      home = {
        inherit username;
        homeDirectory = "/home/${username}";
        stateVersion = "26.05";
      };
    })
  ];
}
