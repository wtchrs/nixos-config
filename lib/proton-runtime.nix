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
      message = "Proton runtime package must provide a steamcompattool output.";
    }
    {
      assertion = lib.all (package: package ? steamcompattool) proton.extraPackages;
      message = "Every Proton runtime extra package must provide a steamcompattool output.";
    }
  ];
}
