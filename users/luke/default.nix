{ config, pkgs, lib, ... }:
{
  nix.settings.trusted-users = [ "luke" ];

  users.users.luke = {
    isNormalUser = true;
    description = "luke";
    extraGroups = [ "networkmanager" "wheel" "podman" ];
    packages = with pkgs; [];
  };

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "luke" ];
  };
}