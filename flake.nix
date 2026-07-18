{
  description = "noob NixOS Flake Configuration";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/release-25.11";

    claude-code-nix.url = "github:sadjow/claude-code-nix";

    claude-skills = {
      url = "github:mattpocock/skills";
      flake = false;
    };

    # disko.url = "github:nix-community/disko";
    # disko.inputs.nixpkgs.follows = "nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
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
    sops-nix,
    ...
  }@inputs:
    let
      system = "x86_64-linux";

      # Every directory under containers/ is a Service declaration and is
      # imported automatically. Disable a service with
      # `homelab.services.<name>.enable = false;` in its own file.
      containerModules = nixpkgs.lib.mapAttrsToList
        (name: _: ./containers/${name})
        (nixpkgs.lib.filterAttrs (_: type: type == "directory")
          (builtins.readDir ./containers));
    in {
      nixosConfigurations = {
        opslag = nixpkgs.lib.nixosSystem {
          inherit system;
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
            ./modules/claude
            ./modules/homelab

            # Disko
            # ./disko/opslag.nix
            # disko.nixosModules.disko

            # Import machine config + secrets
            ./machines/nixos
            ./machines/nixos/opslag

            # Users
            ./users/luke
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit inputs;
                vars = import ./machines/nixos/vars.nix;
              };
              home-manager.users.luke.imports = [
                ./users/luke/dots.nix
              ];
              home-manager.backupFileExtension = "bak";
            }
          ] ++ containerModules;
        };
      };
    };
}
