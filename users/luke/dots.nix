{ inputs, lib, config, pkgs, ... }:
let home = {
  home = {
    username = "luke";
    homeDirectory = "home/luke";
    stateVersion = "";
  };
};
in {
  nixpkgs = {
    overlays = [];
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    }
  }

  home = home;

  imports = [
    ./gitconfig.nix
  ];

  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.home-manager.enable = true;

  systemd.user.startServices = "sd-switch";
}