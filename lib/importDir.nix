{ lib }:

dir:
if !builtins.pathExists dir then
  [ ]
else
  let
    entries = builtins.readDir dir;
    names = builtins.attrNames (
      lib.filterAttrs (
        name: type: type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix"
      ) entries
    );
  in
  map (name: dir + "/${name}") (builtins.sort builtins.lessThan names)
