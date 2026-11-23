{ lib, ... }:

{
  # The niri Home Manager module enables xdg.portal. That points
  # NIX_XDG_DESKTOP_PORTAL_DIR at the user profile, which hides the portal
  # backends that the system installs. The system installs, runs, and
  # selects the portal backends.
  xdg.portal.enable = lib.mkForce false;
}
