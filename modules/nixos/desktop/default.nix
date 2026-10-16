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

  programs.localsend = {
    enable = true;
    # LocalSend requires TCP/UDP port 53317 to receive files
    openFirewall = true;
  };

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
