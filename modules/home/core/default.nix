{ pkgs, ... }:

{
  imports = [
    ../shell
    ../programs/btop.nix
    ./git.nix
    ./environment.nix
    ./networking.nix
    ./security.nix
    ./system-tools.nix
  ];

  home.packages = with pkgs; [
    # Codex runtime
    bubblewrap

    # Archives and compression
    zip
    xz
    unzip
    p7zip
    zstd

    # Search, filtering, and navigation
    ripgrep
    jq
    yq-go
    fzf

    # Command-line utilities
    cowsay
    expect
    file
    which
    tree
    gnused
    gnutar
    gawk

    # Markdown viewer
    glow
  ];

  programs = {
    home-manager.enable = true;
    nh.enable = true;
  };
}
