_:

{
  # Define nvidia-specific environments in niri.
  programs.niri.settings.environment = {
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    __GL_VRR_ALLOWED = "1";
    NVD_BACKEND = "direct";
  };
}
