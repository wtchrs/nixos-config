{ flake, username, ... }:

{
  users.users.${username}.extraGroups = [ "input" ];
  boot.kernelModules = [ "uinput" ];

  # Neru captures keyboard input and re-emits it through a virtual device.
  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0660"
  '';

  home-manager.users.${username}.imports = [ flake.self.homeModules.programs-neru ];
}
