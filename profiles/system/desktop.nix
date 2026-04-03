{ pkgs, username, ... }:

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

  environment.systemPackages = with pkgs; [
    glib.bin
    flatpak-xdg-utils
    sddm-astronaut
  ];

  services = {
    seatd = {
      enable = true;
      user = username;
    };

    gvfs.enable = true;
    tumbler.enable = true;
    flatpak.enable = true;

    displayManager.sddm = {
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
  };

  security = {
    polkit.enable = true;
    rtkit.enable = true;
  };

  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [
      thunar-volman
      thunar-archive-plugin
    ];
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    config.common.default = "gtk";
  };

  systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    '';
  };

  fonts = {
    enableDefaultPackages = true;
    fontDir.enable = true;

    packages = with pkgs; [
      sarasa-mono-k-nerd-font
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      source-code-pro
      source-han-mono
      source-han-sans
      source-han-serif
      font-awesome
      fira-sans
      fira-code
    ];
  };
}
