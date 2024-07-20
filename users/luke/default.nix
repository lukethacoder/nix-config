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
  
  email = {
    fromAddress = "dev@lukesecomb.digital";
    toAddress = "server_announcements@mailbox.org";
    # smtpServer = "email-smtp.eu-west-1.amazonaws.com";
    # smtpUsername = "";
    # smtpPasswordPath = config.age.secrets.smtpPassword.path;
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

  programs.ssh = {
    extraConfig = ''
      Host *
          IdentityAgent ~/.1password/agent.sock
    '';
  };
}