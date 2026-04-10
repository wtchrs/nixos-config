{ pkgs, username, ... }:

{
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
      "networkmanager"
      "video"
      "input"
      "render"
    ];
    shell = pkgs.zsh;
  };
}
