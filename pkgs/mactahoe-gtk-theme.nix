{ lib
, stdenvNoCC
, fetchFromGitHub
, gnutar
, xz
}:

stdenvNoCC.mkDerivation rec {
  pname = "mactahoe-gtk-theme";
  version = "unstable-2026-04-12";

  src = fetchFromGitHub {
    owner = "vinceliuice";
    repo = "MacTahoe-gtk-theme";
    rev = "2026-02-20";
    hash = "sha256-kqvOQETFuTHQObl14tw8IzN1k/W6msSi6lgVQGZtZM0=";
  };

  nativeBuildInputs = [ gnutar xz ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/themes"

    for archive in release/*.tar.xz; do
      tar -xJf "$archive" -C "$out/share/themes"
    done

    runHook postInstall
  '';

  meta = with lib; {
    description = "MacTahoe GTK themes";
    homepage = "https://github.com/vinceliuice/MacTahoe-gtk-theme";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
