{
  lib,
  config,
  username,
  ...
}:

let
  cfg = config.my.features.nvidia;
in
{
  options.my.features.nvidia.enable = lib.mkEnableOption "NVIDIA stack";

  config = lib.mkIf cfg.enable {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    hardware.nvidia = {
      modesetting.enable = true;

      powerManagement.enable = true;
      powerManagement.finegrained = false;

      open = false;

      nvidiaSettings = true;

      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    services.xserver.videoDrivers = [ "nvidia" ];
  };
}
