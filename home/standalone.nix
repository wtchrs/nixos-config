{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  nix = {
    package = pkgs.nix;
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  targets.genericLinux = {
    enable = true;
    gpu.enable = true;
  };
}
