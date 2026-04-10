{
  lib,
  username,
  pkgs,
  ...
}:

let
  importDir = import ../../lib/importDir.nix { inherit lib; };
in
{
  imports = [ ./hardware-configuration.nix ] ++ importDir ./system;

  home-manager.users.${username}.imports = importDir ./home;

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

  # Use CachyOS-fatched kernel
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto-x86_64-v3;

  # Do not change after installation.
  system.stateVersion = "26.05";
}
