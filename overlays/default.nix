inputs:

[
  # overlays
  inputs.nix-cachyos-kernel.overlays.pinned
  inputs.niri.overlays.niri
  (import ./catnap.nix)
  (import ./tmux-dotbar.nix)
]
