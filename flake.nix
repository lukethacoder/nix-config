{
  description = "noob NixOS Flake Configuration";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/release-24.11";

    # disko.url = "github:nix-community/disko";
    # disko.inputs.nixpkgs.follows = "nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
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
      # overlays = [
      #   (self: super: {
      #     go = super.go_1_24;
      #   })
      #   # (final: prev: {
      #   #   # override go version to fix sops-nix issue?
      #   #   go = final.pkgs.go_1_24;
      #   #   sops-install-secrets = prev.sops-install-secrets.overrideAttrs (oldAttrs: {
      #   #     buildInputs = (oldAttrs.buildInputs or []) ++ [ final.pkgs.go_1_24 ];
      #   #   });
      #   # })
      # ];
      # overlays = [
      #   (final: prev: {
      #     sops-install-secrets = prev.sops-install-secrets.overrideAttrs (oldAttrs: {
      #       buildInputs = (oldAttrs.buildInputs or []) ++ [ final.pkgs.go_1_23 ];
      #     });
      #   })
      # ];
      pkgs = import nixpkgs {
        inherit system;
        # inherit overlays;
      };
    in {
      nix.extraOptions = ''
        plugin-files = ${pkgs.nix-plugins}/lib/nix/plugins
      '';
      nixosConfigurations = {
        opslag = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
            vars = import ./machines/nixos/vars.nix;
          };
          modules = [
            # Base configuration and modules
            ./modules/system
            ./modules/sops
            # no longer used
            # ./modules/tailscale
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

            # Services and applications
            ./containers/homepage
            ./containers/traefik
            ./containers/deluge
            # ./containers/qbittorrent
            # ./containers/grafana
            ./containers/jellyfin
            ./containers/navidrome
            ./containers/copyparty
            # TODO: fix immich config
            # ./containers/immich
            # ./containers/homeassistant

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
