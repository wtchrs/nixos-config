{ lib, ... }:

{
  options.my.features = {
    desktop = {
      enable = lib.mkEnableOption "Desktop environment";
      # If desktop.displayManager is disabled, desktop session should be launched in TTY.
      displayManager.enable = lib.mkEnableOption "Display manager setup";
    };
    gaming.enable = lib.mkEnableOption "Gaming setup";
    nvidia.enable = lib.mkEnableOption "NVIDIA stack";
  };
}
