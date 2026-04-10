{ inputs, lib, config, pkgs, username, ... }:

let
  cfg = config.my.features.desktop;
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  options.my.features.desktop.enable = lib.mkEnableOption "Desktop environment";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      glib.bin
      flatpak-xdg-utils
      sddm-astronaut
      bibata-cursors
      nautilus
    ];

    distro-grub-themes = {
      enable = true;
      theme = "nixos";
    };

    services = {
      seatd = {
        enable = true;
        user = username;
      };

      gvfs.enable = true;
      tumbler.enable = true;
      flatpak.enable = true;
      upower.enable = true;
      playerctld.enable = true;

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

      fontconfig = {
        enable = true;
        localConf = ''
          <fontconfig>
            <alias>
              <family>Sarasa Mono K</family>
              <accept>
                <family>Symbols Nerd Font Mono</family>
                <family>Noto Color Emoji</family>
              </accept>
            </alias>
          </fontconfig>
        '';
      };
    };

    # Home manager config
    home-manager.users.${username} = {
      imports = [
        ../../home/niri
        ../../home/quickshell
        ../../home/programs/ghostty.nix
        ../../home/programs/dunst.nix
        ../../home/misc/fonts.nix
        ../../home/misc/input.nix
        ../../home/misc/cursor.nix
      ];

      home.packages = with pkgs; [
        jetbrains-toolbox
        inputs.zen-browser.packages.${system}.default
        spotify
      ];

      programs = {
        vesktop.enable = true;
      };

      xdg.terminal-exec = {
        enable = true;
        settings = {
          default = [ "com.mitchellh.ghostty.desktop" ];
          niri = [ "com.mitchellh.ghostty.desktop" ];
        };
      };
    };
  };
}
