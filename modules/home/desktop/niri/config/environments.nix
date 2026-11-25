{
  # These apply only to processes that niri spawns. Variables shared with labwc,
  # TTY, and SSH sessions are in home.sessionVariables. niri --session and the
  # login manager already set XDG_CURRENT_DESKTOP and XDG_SESSION_*.
  wayland.windowManager.niri.settings.environment = {
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    # Fall back to XWayland for SDL games that lack Wayland support.
    SDL_VIDEODRIVER = "wayland,x11";
    MOZ_DISABLE_RDD_SANDBOX = "1";
  };
}
