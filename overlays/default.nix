inputs:

{
  nixpkgs.overlays = [
    inputs.nix-cachyos-kernel.overlays.pinned
    inputs.niri.overlays.niri
    (import ./tmux-dotbar.nix)
    (import ./sarasa-mono-k-nerd-font.nix)
  ];
}
