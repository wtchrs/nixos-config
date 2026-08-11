final: prev:

let
  uuid = "top-bar-organizer-plus@shibasishpaul.github.com";
in
{
  gnomeExtensions = prev.gnomeExtensions // {
    top-bar-organizer-plus = final.stdenvNoCC.mkDerivation rec {
      pname = "gnome-shell-extension-top-bar-organizer-plus";
      version = "17.1";

      src = final.fetchurl {
        url = "https://github.com/ShibasishPaul/top-bar-organizer-plus/releases/download/v${version}/${uuid}.shell-extension.zip";
        hash = "sha256-Eihtf11NXqrP+ileIyGbUZJ9dxfix2k2a6OJg3AQU1k=";
      };

      nativeBuildInputs = [
        final.unzip
        final.glib
      ];

      dontUnpack = true;

      installPhase = ''
        runHook preInstall

        extensionDir="$out/share/gnome-shell/extensions/${uuid}"
        mkdir -p "$extensionDir"

        unzip "$src" -d "$extensionDir"

        if [ -d "$extensionDir/schemas" ]; then
          glib-compile-schemas --strict "$extensionDir/schemas"
        fi

        runHook postInstall
      '';

      passthru = {
        extensionUuid = uuid;
      };

      meta = {
        description = "Organize the items of the GNOME Shell top bar";
        homepage = "https://github.com/ShibasishPaul/top-bar-organizer-plus";
        license = final.lib.licenses.gpl3Plus;
        platforms = final.lib.platforms.linux;
      };
    };
  };
}
