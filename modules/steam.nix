{ pkgs, ... } :

{
  environment.systemPackages = with pkgs; [
    mangohud
    gamemode

    # protonup-qt
  ];

  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
  };
}
