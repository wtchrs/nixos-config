{ lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    # GnuPG
    gnupg
  ];

  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentry.package = lib.mkDefault pkgs.pinentry-tty;

    defaultCacheTtl = 0;
    maxCacheTtl = 0;
    defaultCacheTtlSsh = 0;
    maxCacheTtlSsh = 0;

    noAllowExternalCache = true;
  };
}
