{ pkgs, ... }:

{
  # Use CachyOS-fatched kernel
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto-x86_64-v3;
}
