{ flake, ... }:

let
  inherit (flake) self;
  username = "ubuntu";
  hostName = "srv-cloud-1";
in
{
  imports = [
    self.homeModules.standalone
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
