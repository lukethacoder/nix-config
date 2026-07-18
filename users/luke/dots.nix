{ inputs, specialArgs, lib, config, pkgs, ... }:
{
  programs.home-manager.enable = true;
  home.stateVersion = "24.05";

  imports = [
    ./claude-skills.nix
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
    enableDefaultConfig = false;
    matchBlocks."*" = {
      identityFile = "~/.ssh/id_ed25519";
    };
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
