{ lib, pkgs }:

let
  proton = rec {
    name = "DW-Proton";
    package = pkgs.dwproton-bin.override {
      steamDisplayName = name;
    };
    extraPackages = [ ];
  };
in
proton
// {
  assertions = [
    {
      assertion = proton.package ? steamcompattool;
      message = "gaming proton package must provide a steamcompattool output.";
    }
    {
      assertion = lib.all (package: package ? steamcompattool) proton.extraPackages;
      message = "Every gaming proton extra package must provide a steamcompattool output.";
    }
  ];
}
