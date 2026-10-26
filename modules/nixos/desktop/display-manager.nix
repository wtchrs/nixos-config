{
  flake,
  pkgs,
  username,
  ...
}:

let
  greeterConfig = "/var/lib/dms-greeter/.config/labwc";
  cursorEnvironment = pkgs.writeText "dms-greeter-cursor-environment" ''
    XCURSOR_THEME=Bibata-Modern-Ice
    XCURSOR_SIZE=24
    XCURSOR_PATH=${pkgs.bibata-cursors}/share/icons
  '';
in
{
  environment.systemPackages = [ pkgs.bibata-cursors ];

  # Configure labwc inside the greeter session, after greetd sets its environment.
  systemd.tmpfiles.rules = [
    "d /var/lib/dms-greeter/.config 0750 dms-greeter dms-greeter -"
    "d ${greeterConfig} 0750 dms-greeter dms-greeter -"
    "L+ ${greeterConfig}/environment - - - - ${cursorEnvironment}"
  ];

  services.displayManager = {
    sessionPackages = [
      pkgs.niri
    ];

    dms-greeter = {
      enable = true;
      package = flake.inputs.dms-greeter.packages.${pkgs.stdenv.hostPlatform.system}.default;
      compositor.name = "labwc";
      # DMS 2.0 stores its configuration under dms instead of DankMaterialShell.
      configFiles = [
        "/home/${username}/.config/dms/settings.json"
        "/home/${username}/.local/state/dms/session.json"
        "/home/${username}/.cache/dms/dms-colors.json"
      ];
    };
  };
}
