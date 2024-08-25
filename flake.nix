{
  description = "noob NixOS Flake Configuration";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/release-24.05";
    
    # disko.url = "github:nix-community/disko";
    # disko.inputs.nixpkgs.follows = "nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Load agenix secrets from private repository
    secrets = {
      url = "git+file:///home/luke/Github/nix-private";
      flake = false;
      # submodules = true;
    };
  };

  outputs = {
    self,
    nixpkgs,
    # disko,
    home-manager,
    agenix,
    secrets,
    ...
  }@inputs:
    {
      nixosConfigurations = {
        opslag = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
            vars = import ./machines/nixos/vars.nix;
          };
          modules = [
            # Base configuration and modules
            ./modules/fonts
            ./modules/gnome
            ./modules/podman
            ./modules/email

            # Disko
            # ./disko/opslag.nix
            # disko.nixosModules.disko

            # Import machine config + secrets
            ./machines/nixos
            ./machines/nixos/opslag
            # ./secrets
            secrets
            agenix.nixosModules.default

            # Services and applications
            ./containers/homepage
            ./containers/traefik
            ./containers/jellyfin

            # Users
            ./users/luke
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit inputs; };
              home-manager.users.luke.imports = [
                agenix.homeManagerModules.default
                # nix-index-database.hmModules.nix-index
                ./users/luke/dots.nix
              ];
              home-manager.backupFileExtension = "bak";
            }
          ];
        };
      };
    };
}
