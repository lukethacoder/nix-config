{ config, pkgs, lib, ... }:
{
  nix.settings.trusted-users = [ "luke" ];

  users.groups.share = {
    gid = 993;
  };

  users.users.luke = {
    isNormalUser = true;
    description = "luke";
    extraGroups = [ "share" "networkmanager" "wheel" "podman" ];
    packages = with pkgs; [];
  };

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "luke" ];
  };
}