final: prev:
{
  catnap = prev.stdenv.mkDerivation (finalAttrs: {
    pname = "catnap";
    version = "1.2.1";

    src = prev.fetchFromGitHub {
      owner = "iinsertNameHere";
      repo = "catnap";
      rev = "v${finalAttrs.version}";
      hash = "sha256-/Er/TP/Hv3VeT6UF5xAPgglc9n3pHcTqCc36tBUd9K8=";
    };

    nativeBuildInputs = [ prev.nim ];
    buildInputs = [ prev.pcre2 ];

    buildPhase = ''
      runHook preBuild

      nim c \
        --cincludes:$PWD/src/extern/headers \
        --path:$PWD/src/extern/libraries \
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
      install -Dm644 config/config.toml config/distros.toml -t $out/share/catnap
      install -Dm644 docs/catnap.1 docs/catnap.5 -t $out/share/man/man1

      runHook postInstall
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
