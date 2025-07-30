{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      # home-manager.inputs.nixpkgs inherits "nixpkgs"
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }: {
    # FIX please change the hostname and username to your own
    nixosConfigurations = let
      system = "x86_64-linux";
      username = "wtchrs";
      overlays = [
        # (import ./overlays/filename.nix)
      ];

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

              { nixpkgs.overlays = overlays; }

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
            ++ (nixpkgs.lib.optional enableGames ./modules/steam.nix);
        };
    in {
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
