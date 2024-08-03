{ config, pkgs, lib, ... }:
{
  nix.settings.trusted-users = [ "luke" ];

  users.users.luke = {
    isNormalUser = true;
    description = "luke";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };
}