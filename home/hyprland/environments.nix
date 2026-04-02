{ lib, osConfig ? null, ... } :

let
  videoDrivers =
    if osConfig == null then
      [ ]
    else
      osConfig.services.xserver.videoDrivers or [ ];
in
{
  wayland.windowManager.hyprland.settings.env =
    [
      "NIXOS_OZONE_WL,1"
      "XDG_CURRENT_DESKTOP,Hyprland"
      "XDG_SESSION_TYPE,wayland"
      "XDG_SESSION_DESKTOP,Hyprland"
      "GDK_BACKEND,wayland"
      "QT_QPA_PLATFORM,wayland;xcb"
      "QT_QPA_PLATFORMTHEME,qt6ct"
      "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
      "QT_AUTO_SCREEN_SCALE_FACTOR,1"
      "SDL_VIDEODRIVER,wayland"
      "MOZ_ENABLE_WAYLAND,1"
      "MOZ_DISABLE_RDD_SANDBOX,1"
      "XCURSOR_SIZE,24"
      "ELECTRON_OZONE_PLATFORM_HINT,auto"
    ]
    ++ lib.optionals (lib.elem "nvidia" videoDrivers) [
      "LIBVA_DRIVER_NAME,nvidia"
      "GBM_BACKEND,nvidia-drm"
      "__GLX_VENDOR_LIBRARY_NAME,nvidia"
      "__GL_VRR_ALLOWED,1"
      "WLR_DRM_NO_ATOMIC,1"
      "WLR_NO_HARDWARE_CURSORS,1"
      "NVD_BACKEND,direct"
    ];
}
