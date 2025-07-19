{ config, lib, pkgs, username, ... }:

{
  imports = [
    ./nvidia.nix
    ./hardware-configuration.nix
    ../../modules/system.nix
  ];

  # Use systemd-boot
  boot.loader = {
    efi.canTouchEfiVariables = true;
    systemd-boot.enable = true;
  };

  time.timeZone = "Asia/Seoul";

  console = {
    font = "Lat2-Terminus16";
  #   keyMap = "us";
    useXkbConfig = true; # use xkb.options in tty.
  };

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [];
  networking.firewall.allowedUDPPorts = [];

  environment.systemPackages = with pkgs; [
    neovim
    vim
    git
    curl
    tmux
    htop
    fcitx5
    fcitx5-gtk
    fcitx5-hangul
    fcitx5-configtool
  ];

  # Enable seatd
  services.seatd = {
    enable = true;
    user = username;
  };

  security.polkit.enable = true;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  programs.firefox.enable = true;
  programs.zsh.enable = true;

  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
    };
  };

  # services.kmscon = {
  #   enable = true;
  #   fonts = [
  #     { name = "Iosevka Nerd Font"; package = pkgs.nerd-fonts.iosevka; }
  #   ];
  # };

  # i18n = {
  #   defaultLocale = "en_US.UTF-8";

  #   inputMethod = {
  #     type = "fcitx5";
  #     fcitx5.addons = with pkgs; [ fcitx5-hangul ];
  #   };
  # };

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.iosevka
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      source-code-pro
      source-han-mono
      source-han-sans
      source-han-serif
    ];

    fontDir.enable = true;
  #   fontconfig.enable = true;

  #   fontconfig.defaultFonts = {
  #     emoji = [ "Noto Color Emoji" ];
  #     monospace = [ "Source Han Mono" "Iosevka Nerd Font" ];
  #     sansSerif = [ "Noto Sans CJK SC" ];
  #     serif = [ "Source Han Serif" ];
  #   };
  };

  # Do not change after installation.
  system.stateVersion = "25.05";
}
