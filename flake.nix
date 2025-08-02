{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }: {
    nixosConfigurations = let
      system = "x86_64-linux";
      # FIX please change the username to your own
      username = "wtchrs";

      mkHost =
        { hostname
        , enableGraphics ? false
        , enableGames ? false
        } :
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit username; };

          modules =
            [
              ./hosts/${hostname}
              ./users/${username}/nixos.nix

              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;

                home-manager.extraSpecialArgs = inputs // { inherit username enableGraphics; };
                home-manager.users.${username} = nixpkgs.lib.mkMerge (builtins.map import [
                  ./home/core.nix
                  ./users/${username}/home.nix
                ]);
              }
            ]
            ++ (nixpkgs.lib.optional enableGraphics ./modules/sddm.nix)
            ++ (nixpkgs.lib.optional enableGames ./modules/steam.nix);
        };
    in {
      # FIX please change the hostnames to your own
      my-nixos = mkHost {
        hostname = "my-nixos";
      };

      notebook = mkHost {
        hostname = "notebook";
        enableGraphics = true;
        enableGames = true;
      };
    };
  };
}
