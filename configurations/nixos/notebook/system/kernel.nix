{ pkgs, ... }:

{
  # Use latest linux kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;
}
