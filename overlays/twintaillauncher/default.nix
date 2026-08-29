final: _prev: {
  twintaillauncher-unwrapped = final.callPackage ./twintaillauncher-unwrapped.nix { };
  twintaillauncher = final.callPackage ./twintaillauncher.nix { };
}
