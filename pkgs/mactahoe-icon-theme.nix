{ lib
, stdenvNoCC
, fetchFromGitHub
, bash
, gtk3
, hicolor-icon-theme
, kdePackages
, name ? "MacTahoe"
, themeVariants ? [ "default" ]
, enableBold ? false
}:

let
  validThemeVariants = [
    "default"
    "blue"
    "purple"
    "green"
    "red"
    "orange"
    "yellow"
    "grey"
    "nord"
  ];

  themeFlags =
    lib.concatMapStringsSep " "
      (v: "--theme ${lib.escapeShellArg v}")
      themeVariants;
in

assert lib.all (v: builtins.elem v validThemeVariants) themeVariants;

stdenvNoCC.mkDerivation rec {
  pname = "mactahoe-icon-theme";
  version = "unstable-2026-04-12";

  src = fetchFromGitHub {
    owner = "vinceliuice";
    repo = "MacTahoe-icon-theme";
    rev = "2025-10-16";
    hash = "sha256-2Tj4PmecvVA3T5GmKBkYdkjnspIue/u0LiYPaNMXk10=";
  };

  nativeBuildInputs = [ bash gtk3 ];

  # upstream src/index.theme: Inherits=hicolor,breeze
  propagatedBuildInputs = [
    hicolor-icon-theme
    kdePackages.breeze-icons
  ];

  dontConfigure = true;
  dontBuild = true;
  dontDropIconThemeCache = true;
  dontWrapQtApps = true;

  installPhase = ''
    runHook preInstall

    export HOME="$TMPDIR/home"
    mkdir -p "$HOME" "$out/share/icons"

    patchShebangs .

    ./install.sh \
      --dest "$out/share/icons" \
      --name ${lib.escapeShellArg name} \
      ${themeFlags} \
      ${lib.optionalString enableBold "--bold"}

    runHook postInstall
  '';

  meta = with lib; {
    description = "MacTahoe icon theme";
    homepage = "https://github.com/vinceliuice/MacTahoe-icon-theme";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
}
