{ flake, ... }:

let
  inherit (flake) self;
  username = "wtchrs";
  hostName = "srv-cloud-1";
in
{
  imports = [
    self.homeModules.core
    self.homeModules.identity-git-gpg
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
