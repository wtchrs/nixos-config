{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Download clients
    curl
    wget
    aria2

    # Network diagnostics
    mtr
    iperf3
    dnsutils
    ldns
    socat
    nmap
    ipcalc
    ethtool
  ];
}
