{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # GnuPG
    gnupg
  ];

  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-tty; # or `pinentry-curses`, `pkgs.pinentry-gnome3`

    defaultCacheTtl = 0;
    maxCacheTtl = 0;
    defaultCacheTtlSsh = 0;
    maxCacheTtlSsh = 0;

    noAllowExternalCache = true;
  };
}
