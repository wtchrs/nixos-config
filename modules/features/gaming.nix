{
  lib,
  pkgs,
  ...
}:

let
  proton = import ../../lib/gaming-proton.nix { inherit lib pkgs; };
in
{
  inherit (proton) assertions;

  environment.systemPackages = with pkgs; [
    mangohud
    gamemode
    umu-launcher
  ];

  programs = {
    steam = {
      enable = true;
      extraCompatPackages = [ proton.package ] ++ proton.extraPackages;
    };

    gamescope = {
      enable = true;
    };
  };
}
