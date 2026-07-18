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
      gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
      commit.gpgsign = true;
      user = {
        signingKey = "${config.home.homeDirectory}/.ssh/id_ed25519";
      };
      push.autoSetupRemote = true;
    };
  };
}