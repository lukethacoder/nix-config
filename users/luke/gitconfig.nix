{ inputs, lib, config, pkgs, ... }:
{
  programs.git = {
    enable = true;
    userName = "lukethacoder";
    userEmail = "13529535+lukethacoder@users.noreply.github.com";

    aliases = {
      s = "status";
      p = "push";
      pl = "pull";
      cm = "commit -m";
      a = "add";
      f = "fetch";
      c = "checkout";
    };

    extraConfig = {
      gpg.format = "ssh";
      gpg."ssh".program = "${lib.getExe' pkgs._1password-gui "op-ssh-sign"}";
      gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
      commit.gpgsign = true;
      user = {
        signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKeuZFjh8UB3SPd8jwt6Mf2BLy0sQbThWN7HyssvxMvI";
      };
      push.autoSetupRemote = true;
    };
  };
}