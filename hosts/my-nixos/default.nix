{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/system.nix
  ];

  # Use systemd-boot
  boot.loader = {
    efi.canTouchEfiVariables = true;
    systemd-boot.enable = true;
  };

  time.timeZone = "Asia/Seoul";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
  #   font = "Lat2-Terminus16";
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

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  environment.systemPackages = with pkgs; [
    neovim vim git curl tmux htop
  ];

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

  # Do not change after installation.
  system.stateVersion = "25.05";
}
