{ pkgs, ... }:

{
  imports = [
    ../shell
    ../programs/btop.nix
    ./git.nix
    ./development.nix
    ./networking.nix
    ./productivity.nix
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
    eza
    fzf

    # Core command-line utilities
    cowsay
    file
    which
    tree
    gnused
    gnutar
    gawk

    # Document and content tools
    hugo
    glow
  ];

  programs.home-manager.enable = true;
}
