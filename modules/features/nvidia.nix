{ lib, config, username, ... }:

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

    # nvidia-specific environment configuration for niri
    home-manager.users.${username}.programs.niri.settings.environment = {
      LIBVA_DRIVER_NAME = "nvidia";
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      __GL_VRR_ALLOWED = "1";
      NVD_BACKEND = "direct";
    };
  };
}
