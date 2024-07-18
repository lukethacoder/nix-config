{
  description = "noob NixOS Flake Configuration";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/release-24.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
    {
      nixosConfigurations = {
        opslag = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            vars = import ./machines/nixos/vars.nix;
          };
          modules = [
            # Base config and modules

            # Import machine config + secrets
            ./machines/nixos/opslag

            # Users
            ./users/luke
            home-manager.nixosModules.home-manager
            {
              home-manager.useGLobalPkgs = false;
              home-manager.extraSpecialArgs = { inherit inputs };
              home-manager.users.luke.imports = [
                agenix.homeManagerModules.default
                nix-index-database.hmModules.nix-index
                ./users/luke/dots.nix
              ];
              home-manager.backupFileExtension = "bak";
            }

          ];
        };
      };
    };
}