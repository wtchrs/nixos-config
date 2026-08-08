{
  flake,
  lib,
  pkgs,
  username,
  ...
}:

let
  inherit (pkgs.stdenv.hostPlatform) system;
  neovim-flake = flake.inputs.neovim-flake.packages.${system}.default;
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
    tailscale = {
      enable = lib.mkDefault true;
      extraSetFlags = [
        "--operator=${username}"
      ];
    };

    openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
    };

    # Resolve executables under /bin and /usr/bin through PATH
    envfs.enable = true;
  };

  virtualisation.docker.enable = true;
}
