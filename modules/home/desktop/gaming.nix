{ config, ... }:

{
  programs.nereid-shell.programProviders = [
    "${config.home.profileDirectory}/bin/umu-exe-list"
  ];
}
