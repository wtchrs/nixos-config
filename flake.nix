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
    nixosConfigurations = {
      # FIX please change the hostname and username to your own
      my-nixos = let
        username = "wtchrs";
        specialArgs = { inherit username; };
      in nixpkgs.lib.nixosSystem {
        inherit specialArgs;
        system = "x86_64-linux";

        modules = [
          ./hosts/my-nixos
          ./users/${username}/nixos.nix

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            home-manager.extraSpecialArgs = inputs // specialArgs;
            # home-manager.users.${username} = import ./users/${username}/home.nix;
            home-manager.users.${username} = nixpkgs.lib.mkMerge (builtins.map import [
              ./home/core.nix
              ./users/${username}/home.nix
            ]);
          }
        ];
      };

      notebook = let
        username = "wtchrs";
        specialArgs = { inherit username; };
      in nixpkgs.lib.nixosSystem {
        inherit specialArgs;
        system = "x86_64-linux";

        modules = [
          ./hosts/notebook
          ./users/${username}/nixos.nix

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            home-manager.extraSpecialArgs = inputs // specialArgs;
            home-manager.users.${username} = nixpkgs.lib.mkMerge (builtins.map import [
              ./home/core.nix
              ./home/graphics.nix
              ./users/${username}/home.nix
            ]);
          }
        ];
      };
    };
  };
}
