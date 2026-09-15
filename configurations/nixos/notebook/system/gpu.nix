{ pkgs, ... }:

{
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;

      extraPackages = with pkgs; [
        intel-media-driver
      ];
    };

    intel-gpu-tools.enable = true;

    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      open = false;
      nvidiaSettings = true;
    };
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  security.wrappers.btop = {
    source = "${pkgs.btop-cuda}/bin/btop";
    owner = "root";
    group = "root";
    capabilities = "cap_perfmon+ep";
    permissions = "0755";
  };
}
