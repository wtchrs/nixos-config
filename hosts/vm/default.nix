{ lib, ... }:

let
  importDir = import ../../lib/importDir.nix { inherit lib; };
in
{
  imports = [ ./hardware-configuration.nix ] ++ importDir ./system;

  # Use systemd-boot
  boot.loader = {
    efi.canTouchEfiVariables = true;
    systemd-boot.enable = true;
  };

  # Do not change after installation.
  system.stateVersion = "26.05";
}
