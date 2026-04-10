{ pkgs, username, ... }:

{
  # enable flake
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  time.timeZone = "Asia/Seoul";
  i18n.defaultLocale = "en_US.UTF-8";

  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  networking = {
    networkmanager.enable = true;
    firewall.allowedTCPPorts = [ ];
    firewall.allowedUDPPorts = [ ];
  };

  services.xserver = {
    xkb = {
      layout = "us";
      options = "ctrl:nocaps";
    };
  };

  # Home manager config
  home-manager.users.${username} = {
    imports = [
      ../../home/shell
      ../../home/programs/btop.nix
    ];

    home = {
      inherit username;
      homeDirectory = "/home/${username}";
    };

    home.packages = with pkgs; [
      zip
      xz
      unzip
      p7zip

      ripgrep
      jq
      yq-go
      eza
      fzf

      duf
      dust

      mtr
      iperf3
      dnsutils
      ldns
      aria2
      socat
      nmap
      ipcalc

      cowsay
      file
      which
      tree
      gnused
      gnutar
      gawk
      zstd
      gnupg

      nix-output-monitor

      hugo
      glow

      htop
      iotop
      iftop

      fastfetch

      strace
      ltrace
      lsof

      sysstat
      lm_sensors
      ethtool
      pciutils
      usbutils
    ];

    programs = {
      git.enable = true;
      gpg.enable = true;
      direnv.enable = true;
      direnv.nix-direnv.enable = true;
    };

    services.gpg-agent = {
      enable = true;
      # pinentry.package = pkgs.pinentry-curses;
      pinentry.package = pkgs.pinentry-gnome3;

      defaultCacheTtl = 0;
      maxCacheTtl = 0;
      defaultCacheTtlSsh = 0;
      maxCacheTtlSsh = 0;

      noAllowExternalCache = true;
    };

    home.stateVersion = "26.05";
  };
}
