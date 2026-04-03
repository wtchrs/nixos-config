{ pkgs, username, ... }:

{
  imports = [
    ../../home/shell
    ../../home/neovim
    ../../home/programs/fastfetch.nix
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
  };

  home.packages = with pkgs; [
    nnn

    zip
    xz
    unzip
    p7zip

    ripgrep
    jq
    yq-go
    eza
    fzf

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
    direnv.enable = true;
    direnv.nix-direnv.enable = true;
  };

  home.stateVersion = "26.05";
}
