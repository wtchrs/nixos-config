{ inputs, lib, pkgs, ... }:

let
  inherit (pkgs.stdenv.hostPlatform) system;
  neovim-flake = inputs.neovim-flake.packages.${system}.default;
in
{
  environment.systemPackages = with pkgs; [
    neovim-flake
    vim
    git
    curl
    tmux
    htop
  ];

  programs = {
    zsh.enable = true;
    mtr.enable = true;

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  services = {
    tailscale.enable = lib.mkDefault true;

    openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
    };
  };

  virtualisation.docker.enable = true;
}
