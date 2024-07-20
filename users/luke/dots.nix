{ inputs, lib, config, pkgs, ... }:
{
  home = {
    username = "luke";
    homeDirectory = "/home/luke";
    stateVersion = "24.05";
  };
  programs.home-manager.enable = true;
  # systemd.user.startServices = "sd-switch";

  nixpkgs = {
    overlays = [];
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    }
  }

  imports = [
    ./gitconfig.nix
  ];

  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };
}