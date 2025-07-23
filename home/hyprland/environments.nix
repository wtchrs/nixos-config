{ ... } :

{
  wayland.windowManager.hyprland.settings = {
    env = [
      # OZONE
      "NIXOS_OZONE_WL, 1"

      # XDG Desktop Portal
      "XDG_CURRENT_DESKTOP,Hyprland"
      "XDG_SESSION_TYPE,wayland"
      "XDG_SESSION_DESKTOP,Hyprland"

      "GDK_BACKEND,wayland"

      # QT
      "QT_QPA_PLATFORM,wayland;xcb"
      "QT_QPA_PLATFORMTHEME,qt6ct"
      "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
      "QT_AUTO_SCREEN_SCALE_FACTOR,1"

      ## SDL
      "SDL_VIDEODRIVER,wayland"

      # Mozilla
      "MOZ_ENABLE_WAYLAND,1"
      "MOZ_DISABLE_RDD_SANDBOX,1"

      # Set the cursor size for xcursor
      "XCURSOR_SIZE,24"

      # NVIDIA https://wiki.hyprland.org/Nvidia/
      "LIBVA_DRIVER_NAME,nvidia"
      "GBM_BACKEND,nvidia-drm"
      "__GLX_VENDOR_LIBRARY_NAME,nvidia"
      "__GL_VRR_ALLOWED,1"
      "WLR_DRM_NO_ATOMIC,1"
      "WLR_NO_HARDWARE_CURSORS,1"
      "ELECTRON_OZONE_PLATFORM_HINT,auto"
      "NVD_BACKEND,direct"
    ];
  };
}
