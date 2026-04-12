final: prev: {
  mactahoe-gtk-theme =
    prev.callPackage ../pkgs/mactahoe-gtk-theme.nix { };

  mactahoe-icon-theme =
    prev.callPackage ../pkgs/mactahoe-icon-theme.nix { };
}
