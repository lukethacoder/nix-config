{ inputs, lib, config, pkgs, ... }:
{
  progams.git = {
    enable = true;
    userName = "lukethacoder";
    userEmail = "13529535+lukethacoder@users.noreply.github.com";

    extraConfig = {
      gpg = {
        format = "ssh";
      };
      "gpg \"ssh\"" = {
        program = "${lib.getExe' pkgs._1password-gui "op-ssh-sign"}";
      };
      commit = {
        gpgsign = true;
      };

      # user = {
      #   signingKey = "";
      # };
    };
  };
}