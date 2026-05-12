inputs:

[
  # overlays
  inputs.nix-cachyos-kernel.overlays.pinned
  inputs.niri.overlays.niri
  (import ./tmux-dotbar.nix)
]
