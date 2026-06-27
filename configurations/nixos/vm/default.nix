{ inputs, ... }:

let
  username = "wtchrs";
  hostName = "vm";
in
{
  imports = [
    (import ../../../modules { inherit inputs; })
    ../../../users/${username}/system.nix

    ./hardware-configuration.nix
  ];

  _module.args = {
    inherit inputs username hostName;
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
