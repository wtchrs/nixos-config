{ pkgs, lib, username, ... } :

{
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "input" "render" ];
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
