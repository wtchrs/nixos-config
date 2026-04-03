{ pkgs, username, ... }:

{
  environment.systemPackages = with pkgs; [
    glib.bin
    flatpak-xdg-utils
    sddm-astronaut
    bibata-cursors
    nautilus
  ];

  services = {
    seatd = {
      enable = true;
      user = username;
    };

    gvfs.enable = true;
    tumbler.enable = true;
    flatpak.enable = true;

    displayManager.sessionPackages = [
      pkgs.niri-unstable
    ];
    displayManager.sddm = {
      enable = true;
      package = pkgs.kdePackages.sddm;
      wayland.enable = true;
      theme = "sddm-astronaut-theme";
      settings = {
        Theme = {
          CursorTheme = "Bibata-Modern-Ice"; # Example theme
          CursorSize = "24";
        };
      };
      extraPackages = with pkgs; [
        sddm-astronaut
        bibata-cursors
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

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gnome ];
    config.common.default = "gnome";
  };

  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "ghostty";
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
      sarasa-gothic
      sarasa-mono-k-nerd-font
      nerd-fonts.symbols-only
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
