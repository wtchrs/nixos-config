{
  pkgs,
  username,
  ...
}:

{
  imports = [
    ./file-manager.nix
    ./flatpak.nix
    ./keyring.nix
    ./desktop-manager.nix
    ./input-method.nix
  ];

  environment.systemPackages = with pkgs; [
    glib.bin
  ];

  services = {
    seatd = {
      enable = true;
      user = username;
    };

    tumbler.enable = true;
    upower.enable = true;
    playerctld.enable = true;

    pipewire = {
      enable = true;
      pulse.enable = true;
    };
  };

  security = {
    # policy kit
    polkit.enable = true;

    # GTK4-based polkit authentication agent
    soteria.enable = true;

    # Asign limited real-time scheduling priorities to time-sensitive processes like audio
    rtkit.enable = true;
  };
}
