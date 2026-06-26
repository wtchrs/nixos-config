{
  config,
  lib,
  pkgs,
  ...
}:

{
  nix = {
    package = pkgs.nix;
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  targets.genericLinux = lib.mkIf config.my.features.desktop.enable {
    enable = true;
    gpu.enable = true;
  };
}
