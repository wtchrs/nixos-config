{ flake, pkgs, ... }:

{
  imports = [ flake.inputs.neru.homeManagerModules.default ];

  # Host prerequisites for Wayland (configure these outside Home Manager):
  # - Add the user to the input group for keyboard device access.
  # - Load the uinput kernel module.
  # - Give the input group write access to /dev/uinput through udev.
  # Example rule: KERNEL=="uinput", GROUP="input", MODE="0660".
  # NixOS notebook manages these in configurations/nixos/notebook/neru.nix.
  # Arch Linux must provide these settings through its host configuration.
  # For standalone Home Manager, configure these prerequisites on the host system.
  services.neru = {
    enable = true;
    # The patched release binary crashes on startup; build against our libraries.
    package = flake.inputs.neru.packages.${pkgs.stdenv.hostPlatform.system}.source;

    settings = {
      # Screen-based hints avoid missing window coordinates in niri and labwc.
      hints.strategy = "contour";

      hotkeys = {
        "Ctrl+Alt+Space" = "hints --capture-scope screen --action left_click";
        "Ctrl+Alt+G" = "grid --action left_click";
        "Ctrl+Alt+C" = "recursive_grid --action left_click";
        "Ctrl+Alt+S" = "scroll";
      };
    };
  };
}
