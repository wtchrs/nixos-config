{ flake, ... }:

let
  inherit (flake) self;
  username = "wtchrs";
  hostName = "vm";
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

    ./hardware-configuration.nix
  ];

  _module.args = {
    inherit username hostName;
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = hostName;

  # Use systemd-boot
  boot.loader = {
    efi.canTouchEfiVariables = true;
    systemd-boot.enable = true;
  };

  networking = {
    networkmanager.enable = true;
    firewall.allowedTCPPorts = [ ];
    firewall.allowedUDPPorts = [ ];
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
