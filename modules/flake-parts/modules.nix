{ inputs, ... }:

{
  flake = {
    nixosModules = {
      default = import ../nixos;

      graphics-desktop = import ../nixos/desktop;
      graphics-display-manager = import ../nixos/desktop/display-manager.nix;
      graphics-gaming = import ../nixos/gaming.nix;
      graphics-grub-theme = import ../nixos/desktop/grub-theme.nix;
      graphics-nvidia = import ../nixos/nvidia.nix;
    };

    homeModules = {
      core = import ../home/core;
      standalone = import ../home/standalone.nix;
      standalone-graphics = import ../home/standalone-graphics.nix;
      nixos = import ../home/nixos.nix;

      graphics-desktop = import ../home/desktop;
      graphics-desktop-gaming = import ../home/desktop/gaming.nix;
      graphics-desktop-nvidia = import ../home/desktop/nvidia.nix;
      graphics-gaming = import ../home/gaming;
      graphics-develop-vscode = import ../home/dev/vscode.nix;

      identity-git-gpg = import ../home/identity/git-gpg.nix;
    };

    lib.gaming-proton = import ../../lib/gaming-proton.nix;

    overlays = {
      cachyos-kernel = inputs.nix-cachyos-kernel.overlays.pinned;
      niri = inputs.niri.overlays.niri;
      catnap = import ../../overlays/catnap.nix;
      tmux-dotbar = import ../../overlays/tmux-dotbar.nix;
      gnome-top-bar-organizer-plus = import ../../overlays/gnome-top-bar-organizer-plus.nix;
    };
  };
}
