{ inputs, ... }:

{
  flake = {
    nixosModules = {
      default = import ../nixos;
      cli = import ../nixos/core/cli.nix;
      remote-access = import ../nixos/remote-access.nix;
      docker = import ../nixos/docker.nix;

      graphics-desktop = import ../nixos/desktop;
      graphics-gaming = import ../nixos/gaming.nix;
      graphics-grub-theme = import ../nixos/desktop/grub-theme.nix;
    };

    homeModules = {
      core = import ../home/core;
      editors = import ../home/editors.nix;
      documents = import ../home/documents.nix;
      development = import ../home/dev;
      development-database-tools = import ../home/dev/database-tools.nix;
      standalone = import ../home/standalone.nix;
      standalone-graphics = import ../home/standalone-graphics.nix;
      nixos = import ../home/nixos.nix;

      graphics-desktop = import ../home/desktop;
      graphics-desktop-nvidia = import ../home/desktop/nvidia.nix;
      graphics-gaming = import ../home/gaming;
      programs-neru = import ../home/programs/neru.nix;
      programs-win-run = import ../home/programs/win-run;
      graphics-develop-vscode = import ../home/desktop/dev/vscode;

      identity-git-gpg = import ../home/identity/git-gpg.nix;
    };

    lib.proton-runtime = import ../../lib/proton-runtime.nix;

    overlays = {
      niri = inputs.niri.overlays.niri;
      catnap = import ../../overlays/catnap.nix;
      twintaillauncher = import ../../overlays/twintaillauncher;
      tmux-dotbar = import ../../overlays/tmux-dotbar.nix;
    };
  };
}
