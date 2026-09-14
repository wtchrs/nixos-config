{
  pkgs,
  username,
  ...
}:

{
  imports = [
    ./display-manager.nix
    ./portal.nix
    ./file-manager.nix
    ./flatpak.nix
    ./keyring.nix
    ./input-method.nix
  ];

  environment.systemPackages = with pkgs; [
    glib.bin
  ];

  programs.labwc.enable = true;

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

    # Asign limited real-time scheduling priorities to time-sensitive processes like audio
    rtkit.enable = true;
  };

}
