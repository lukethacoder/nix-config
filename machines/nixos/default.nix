{ inputs, config, lib, pkgs, ... }:
{
  # DO NOT MANUALLY UPDATE THIS VALUE
  system.stateVersion = "24.05";

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nix.optimise.automatic = true;
  nix.optimise.dates = [ "weekly" ];

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };

  nix = {
    package = pkgs.nix;
    settings.experimental-features = [ "nix-command" "flakes" ];
  };

  programs.git.enable = true;

  services.openssh = {
    enable = true;
    ports = [ 69 ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Starship.rs shell
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;

      directory = {
        truncation_length = 5;
      };
      
      git_status = {
        conflicted = "🏳";
        # up_to_date = "✓";
        untracked = "🤔";
        stashed = "📦";
        modified = "📝";
        staged = "[++\($count\)](green)";
        renamed = "🏷️";
        deleted = "🗑";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    starship
    neofetch
    cinnamon.nemo-with-extensions
    sops
    age
  ];
}