{ pkgs, ... }: {
  services.gnome.gnome-keyring.enable = true;

  environment.systemPackages = with pkgs; [
    seahorse # keyring management GUI
    libsecret
  ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    glibc
    libsecret
  ];
}
