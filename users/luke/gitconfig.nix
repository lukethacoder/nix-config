{ inputs, lib, config, pkgs, ... }:
{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "lukethacoder";
        email = "13529535+lukethacoder@users.noreply.github.com";
        signingKey = "${config.home.homeDirectory}/.ssh/id_ed25519";
      };

      alias = {
        s = "status";
        p = "push";
        pl = "pull";
        cm = "commit -m";
        a = "add";
        f = "fetch";
        c = "checkout";
      };

      gpg.format = "ssh";
      gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
      commit.gpgsign = true;
      push.autoSetupRemote = true;
    };
  };
}