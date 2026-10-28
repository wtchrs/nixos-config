final: prev: {
  catnap = prev.stdenv.mkDerivation (finalAttrs: {
    pname = "catnap";
    version = "2.1.1";

    src = prev.fetchFromGitHub {
      owner = "iinsertNameHere";
      repo = "catnap";
      rev = "v${finalAttrs.version}";
      hash = "sha256-r/bZPrM+HpIcRPlUStDIBaU8ls9+S5g6XBSev4n00hw=";
    };

    patches = [
      ./no-pcre.patch
      ./nix-profile.patch
      ./gpu-fallback.patch
    ];

    nativeBuildInputs = [
      prev.nim
      prev.makeWrapper
    ];

    buildPhase = ''
      runHook preBuild

      nim c \
        --cincludes:$PWD/src/extern/headers \
        --passC:-f \
        --mm:arc \
        --threads:on \
        --panics:on \
        --checks:off \
        --verbosity:0 \
        --hints:off \
        -d:danger \
        --opt:speed \
        -d:strip \
        --nimcache:$TMPDIR/nimcache \
        --out:catnap \
        src/catnap.nim

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      install -Dm755 catnap $out/bin/catnap
      mkdir -p "$out/share/catnap"
      cp -R config/. "$out/share/catnap/"
      install -Dm644 docs/catnap.1 docs/catnap.5 -t $out/share/man/man1

      runHook postInstall
    '';

    postFixup = ''
      wrapProgram "$out/bin/catnap" \
        --prefix PATH : "${
          prev.lib.makeBinPath [
            prev.bash
            prev.coreutils
            prev.mesa-demos
            prev.nix
            prev.pciutils
          ]
        }"
    '';

    meta = {
      description = "Highly customizable system information fetcher";
      homepage = "https://github.com/iinsertNameHere/catnap";
      license = prev.lib.licenses.mit;
      mainProgram = "catnap";
      platforms = prev.lib.platforms.linux;
    };
  });
}
