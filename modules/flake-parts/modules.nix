_:

{
  flake = {
    nixosModules = {
      default = import ../../modules;

      graphics-desktop = import ../../modules/features/desktop;
      graphics-display-manager = import ../../modules/features/desktop/display-manager.nix;
      graphics-gaming = import ../../modules/features/gaming.nix;
      graphics-grub-theme = import ../../modules/features/desktop/grub-theme.nix;
      graphics-nvidia = import ../../modules/features/nvidia.nix;
    };

    homeModules = {
      core = import ../../home/core;
      standalone = import ../../home/standalone.nix;

      graphics-desktop = import ../../home/desktop;
      graphics-desktop-gaming = import ../../home/desktop/gaming.nix;
      graphics-desktop-nvidia = import ../../home/desktop/nvidia.nix;
      graphics-gaming = import ../../home/gaming;

      identity-git-gpg = import ../../home/identity/git-gpg.nix;
    };
  };
}
