{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    neovim
    vim
    git
    curl
    tmux
    htop
  ];

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  programs = {
    firefox.enable = true;
    zsh.enable = true;
    mtr.enable = true;

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
  };
}
