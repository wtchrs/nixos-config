{
  my-nixos = {
    system = "x86_64-linux";
    hostName = "my-nixos";
    hostModule = ../../hosts/my-nixos;
    userModule = ../../users/wtchrs;
    systemProfiles = [ "base" "workstation" ];
    homeProfiles = [ "base" ];
  };

  notebook = {
    system = "x86_64-linux";
    hostName = "notebook";
    hostModule = ../../hosts/notebook;
    userModule = ../../users/wtchrs;
    systemProfiles = [ "base" "workstation" "desktop" "gaming" "nvidia" ];
    homeProfiles = [ "base" "desktop" ];
  };
}
