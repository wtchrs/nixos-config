final: prev: {
  neopane = prev.rustPlatform.buildRustPackage (finalAttrs: {
    pname = "neopane";
    version = "0.2.2";

    src = prev.fetchFromGitHub {
      owner = "spiritledsoftware";
      repo = "neopane";
      rev = "v${finalAttrs.version}";
      hash = "sha256-X70xl065IIIMc8TEUblZmJ5KCyOptwmloT/UOr4fgog=";
    };

    cargoHash = "sha256-yzmRA8zQVVz8TdCCws8IXTQ/NwAxuQvaa7ks7ASSNoo=";

    # The tests start Neovim and terminal multiplexers, which the build sandbox lacks.
    doCheck = false;

    meta = {
      description = "One Neovim in the background, shown in every terminal attached to it";
      homepage = "https://github.com/spiritledsoftware/neopane";
      license = prev.lib.licenses.mit;
      mainProgram = "neopane";
      platforms = prev.lib.platforms.unix;
    };
  });
}
