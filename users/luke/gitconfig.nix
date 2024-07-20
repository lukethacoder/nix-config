{ inputs, lib, config, pkgs, ... }:
{
  progams.git = {
    enable = true;
    userName = "lukethacoder";
    userEmail = "13529535+lukethacoder@users.noreply.github.com";
    signingKey = "SHA256:KPYK9mN30Qf7ui8sI7MXmvlU4uMJCuSjE4uQ3vTx1gU";

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
    };
  };
}