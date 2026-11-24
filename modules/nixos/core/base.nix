{ lib, pkgs, ... }:

{
  # enable flake
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Collect old generations of all profiles, including Home Manager, every week.
  # --keep-one keeps every live direnv gcroot regardless of age, so the last
  # environment of each project survives.
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep-since 14d --keep 5 --keep-one";
    };
  };

  time.timeZone = lib.mkDefault "Asia/Seoul";
  i18n.defaultLocale = "en_US.UTF-8";

  console = {
    packages = [ pkgs.terminus_font ];
    font = "ter-v20b";
    earlySetup = true;
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
