{ config, pkgs, lib, ... }:
{
  nix.settings.trusted-users = [ "luke" ]; 

  users = {
    users = {
      luke = {
        shell = pkgs.zsh;
        uid = 1000;
        isNormalUser = true;
        extraGroups = [ "wheel" "users" ];
        group = "luke";
        packages = with pkgs; [];
      };
    };
    groups = {
      luke = {
        gid = 1000;
      };
    };
  };

  programs.zsh.enable = true;

  # 1password
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # Certain features, including CLI integration and system authentication support,
    # require enabling PolKit integration on some desktop environments (e.g. Plasma).
    polkitPolicyOwners = [ "luke" ];
  };

  _: let
    # onePassPath = "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
    onePassPath = "~/.1password/agent.sock";
  in {
    programs.ssh = {
      enable = true;
      extraConfig = ''
        Host *
            IdentityAgent ${onePassPath}
      '';
    };
  }
}