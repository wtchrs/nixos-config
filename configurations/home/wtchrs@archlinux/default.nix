{ flake, ... }:

let
  inherit (flake) self;
  username = "wtchrs";
  hostName = "archlinux";
in
{
  imports = [
    self.homeModules.standalone
    self.homeModules.standalone-graphics
    self.homeModules.core
    self.homeModules.graphics-desktop
    self.homeModules.graphics-gaming
    self.homeModules.graphics-desktop-gaming
    self.homeModules.graphics-desktop-nvidia
    self.homeModules.identity-git-gpg
    ../../nixos/notebook/home/display-outputs.nix
  ];

  _module.args = {
    inherit username hostName;
  };

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = "26.05";
  };
}
