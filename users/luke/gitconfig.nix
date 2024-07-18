{ inputs, lib, config, pkgs, ... }:
{
  progams.git = {
    enable = true;
    userName = "lukethacoder";
    userEmail = "13529535+lukethacoder@users.noreply.github.com";

    # extraConfig.core.sshCommand = "ssh -o 'IdentitiesOnly=yes' -i ~/.ssh/luke";
  };
}