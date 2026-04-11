{ lib, ... }:

{
  options.my.features = {
    desktop.enable = lib.mkEnableOption "Desktop environment";
    gaming.enable = lib.mkEnableOption "Gaming setup";
    nvidia.enable = lib.mkEnableOption "NVIDIA stack";
  };
}
