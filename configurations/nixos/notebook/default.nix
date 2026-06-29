{ flake, ... }:

let
  inherit (flake) inputs self;
  username = "wtchrs";
  hostName = "notebook-nixos";
in
{
  imports = [
    self.nixosModules.default
    ({ pkgs, ... }: {
      users.users.${username} = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "networkmanager"
          "render"
        ];
        shell = pkgs.zsh;
      };
    })

    self.nixosModules.graphics-desktop
    self.nixosModules.graphics-display-manager
    self.nixosModules.graphics-nvidia
    self.nixosModules.graphics-gaming

    inputs.grub2-themes.nixosModules.default
    self.nixosModules.graphics-grub-theme

    ./hardware-configuration.nix
    ./system/kernel.nix
    ./system/gpu.nix
    ./system/nix-ld.nix
    ./system/power.nix
  ];

  _module.args = {
    inherit username hostName;
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = hostName;

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
    self.homeModules.core
    self.homeModules.graphics-desktop
    self.homeModules.graphics-gaming
    self.homeModules.graphics-desktop-gaming
    self.homeModules.graphics-desktop-nvidia
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
    ./home/display-outputs.nix
  ];
}
