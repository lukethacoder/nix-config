{ inputs, config, pkgs, lib, ... }:
{
  system.stateVersion = "24.05";

  nix.settings.experimental-features = lib.mkDefault [ "nix-command" "flakes" ];

  nixpkgs = {
    config = {
      allowUnfree = true;
      # allowUnfreePredicate = (_: true);
    };
  };
  
  programs.git.enable = true;

  environment.systemPackages = with pkgs; [
    jq
    git-crypt
  ];
}