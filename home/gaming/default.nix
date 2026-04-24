{
  lib,
  pkgs,
  config,
  ...
}:

{
  config = lib.mkIf config.my.features.gaming.enable {
    home.packages = [
      (pkgs.callPackage ../../pkgs/twintaillauncher-bin.nix { })
    ];
  };
}
