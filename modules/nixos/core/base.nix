{ lib, ... }:

{
  # enable flake
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  time.timeZone = lib.mkDefault "Asia/Seoul";
  i18n.defaultLocale = "en_US.UTF-8";

  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  services.xserver = {
    xkb = {
      layout = "us";
      options = "ctrl:nocaps";
    };
  };

  # Resolve executables under /bin and /usr/bin through PATH
  services.envfs.enable = true;
}
