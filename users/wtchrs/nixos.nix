{ pkgs, username, ... } :

{
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "input" "render" ];
    shell = pkgs.zsh;
  };
}
