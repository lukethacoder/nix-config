{ inputs, specialArgs, lib, config, pkgs, ... }:
{
  programs.home-manager.enable = true;
  home.stateVersion = "24.05";

  imports = [
    ./gitconfig.nix
    ./vscode.nix
    ./zed.nix
  ];

  home = {
    username = "luke";
    homeDirectory = "/home/luke";
    packages = with pkgs; [
      _1password-cli
      _1password-gui
    ];
  };

  home.file.".ssh/allowed_signers".text = "* ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKeuZFjh8UB3SPd8jwt6Mf2BLy0sQbThWN7HyssvxMvI";

  programs.ssh = {
    enable = true;
    # Host github.com
    #   IdentityAgent ~/.ssh/id_ed25519
    extraConfig = ''
    Host *
      IdentityAgent ~/.1password/agent.sock
    '';
  };

  dconf.settings = {
    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
    };
  };

  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 1800;
    enableSshSupport = true;
  };
}
