{ pkgs, ... } :

{
  programs.hyprland.enable = true;

  environment.etc."xdg/xsessions/hyprland.desktop".text = ''
    [Desktop Entry]
    Name=Hyprland
    Comment=Wayland compositor
    Exec=Hyprland
    Type=Application
    DesktopNames=Hyprland
  '';

  environment.systemPackages = with pkgs; [ sddm-astronaut ];

  services.displayManager.sddm = {
    enable = true;
    package = pkgs.kdePackages.sddm;
    wayland.enable = true;
    theme = "sddm-astronaut-theme";
    extraPackages = with pkgs; [
      sddm-astronaut
      kdePackages.qtsvg
      kdePackages.qtmultimedia
      kdePackages.qtvirtualkeyboard
    ];
  };
}
