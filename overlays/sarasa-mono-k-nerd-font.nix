final: prev: {
  sarasa-mono-k-nerd-font = prev.stdenv.mkDerivation {
    pname = "sarasa-mono-k-nerd-font";
    version = "1.0.32-0";

    src = prev.fetchzip {
      url = "https://github.com/jonz94/Sarasa-Gothic-Nerd-Fonts/releases/download/v1.0.32-0/sarasa-mono-k-nerd-font.zip";
      sha256 = "sha256-29brjHFRV/a2isuNLhII82TdlhBwbZI264DAdw037nc=";
      stripRoot = false;
    };

    installPhase = ''
      mkdir -p $out/share/fonts/TTF
      cp *.ttf $out/share/fonts/TTF/
    '';

    meta = with prev.lib; {
      description = "Sarasa Mono K patched with Nerd Font";
      license = licenses.mit;
    };
  };
}
