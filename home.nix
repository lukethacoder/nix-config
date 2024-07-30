{ config, lib, pkgs, ... }:

{
  home.username = "luke";
  home.homeDirectory = "/home/luke";

  home.packages = with pkgs; [
    _1password
    _1password-gui
  ];

  home.file.".ssh/allowed_signers".text = "* ssh-rsa ABC123";

  programs.ssh = {
    enable = true;
    extraConfig = ''
      Host *
          IdentityAgent ~/.1password/agent.sock
    '';
  };
  
  programs.git = {
    enable = true;
    userName = "lukethacoder";
    userEmail = "13529535+lukethacoder@users.noreply.github.com";

    aliases = {
      s = "status";
      p = "push";
      cm = "commit -m";
      a = "add";
    };

    extraConfig = {
      gpg.format = "ssh";
      gpg."ssh".program = "${lib.getExe' pkgs._1password-gui "op-ssh-sign"}";
      gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
      commit.gpgsign = true;
      user = {
        signingKey = "ssh-rsa ABC123";
      };
      push.autoSetupRemote = true;
    };
  };

  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 1800;
    enableSshSupport = true;
  };

  home.stateVersion = "24.05";

  programs.home-manager.enable = true;
}
