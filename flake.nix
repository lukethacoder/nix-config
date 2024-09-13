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

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Load secrets from private repository
    nix-secrets = {
      url = "git+ssh://git@github.com/lukethacoder/nix-private.git?ref=main&shallow=1";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    # disko,
    home-manager,
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
            ./modules/sops
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
            # nix-secrets
            # ./secrets
            # inputs.secrets
            # builtins.toString secrets
            # agenix.nixosModules.default

            # Services and applications
            ./containers/homepage
            ./containers/traefik
            ./containers/jellyfin
            ./containers/gonic
            ./containers/lms

            # Users
            ./users/luke
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit inputs; };
              home-manager.users.luke.imports = [
                # agenix.homeManagerModules.default
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
