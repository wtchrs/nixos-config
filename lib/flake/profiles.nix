_:

let
  systemProfiles = {
    base = ../../profiles/system/base.nix;
    workstation = ../../profiles/system/workstation.nix;
    desktop = ../../profiles/system/desktop.nix;
    gaming = ../../profiles/system/gaming.nix;
    nvidia = ../../profiles/system/nvidia.nix;
  };

  homeProfiles = {
    base = ../../profiles/home/base.nix;
    desktop = ../../profiles/home/desktop.nix;
  };

  resolveProfiles =
    kind: registry: names:
    builtins.map (name: registry.${name} or (throw "Unknown ${kind} profile `${name}`")) names;
in
{
  system = systemProfiles;
  home = homeProfiles;

  getSystemModules = names: resolveProfiles "system" systemProfiles names;
  getHomeModules = names: resolveProfiles "home" homeProfiles names;
}
