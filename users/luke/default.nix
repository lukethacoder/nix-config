{ config, pkgs, lib, ... }:
{
  nix.settings.trusted-users = [ "luke" ]; 

  users = {
    users = {
      luke = {
        shell = pkgs.zsh;
        uid = 1000;
        isNormalUser = true;
        extraGroups = [ "wheel" "users" ];
        group = "luke";
      };
    };
    groups = {
      luke = {
        gid = 1000;
      };
    };
  }

  programs.zsh.enable = true;
}