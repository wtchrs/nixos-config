{ inputs, pkgs, ... }:

let
  inherit (pkgs.stdenv.hostPlatform) system;
  neovim-flake = inputs.neovim-flake.packages.${system}.default;
in
{
  imports = [
    ../shell
    ../programs/btop.nix
  ];

  home.packages = with pkgs; [
    neovim-flake
    vim

    zip
    xz
    unzip
    p7zip

    curl
    wget

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
}
