{ pkgs, ... }:

{
  hardware.intel-gpu-tools.enable = true;

  security.wrappers.btop = {
    source = "${pkgs.btop-cuda}/bin/btop";
    owner = "root";
    group = "root";
    capabilities = "cap_perfmon+ep";
    permissions = "0755";
  };
}
