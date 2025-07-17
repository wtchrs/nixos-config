{ config, pkgs, username, ... } :

{
  imports = [
    ./programs
  ];

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-hyprland ];
  };

  wayland.windowManager.hyprland = {
    enable = true;

    settings  = {
      "$mainMod" = "SUPER";

      bind = [
        "$mainMod, RETURN, exec, alacritty"
        "$mainMod, Q, killactive"
        "$mainMod, f, exec, firefox"
      ];
    };

    extraConfig = ''
      env = LIBVA_DRIVER_NAME,nvidia
      env = GBM_BACKEND,nvidia-drm
      env = __GLX_VENDOR_LIBRARY_NAME,nvidia
      env = __GL_VRR_ALLOWED,1
      env = WLR_DRM_NO_ATOMIC,1
      env = WLR_NO_HARDWARE_CURSORS,1
      env = NVD_BACKEND,direct

      monitor = ,1920x1080,auto,1.2
    '';
  };
}
