{
  targets.genericLinux = {
    enable = true;
    gpu.enable = true;
  };

  # NixOS hosts start gnome-keyring through PAM. Other distributions get it from Home Manager.
  services.gnome-keyring.enable = true;
}
