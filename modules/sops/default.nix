{ pkgs, inputs, config, configVars, ... }:
let
  secretsDirectory = builtins.toString inputs.nix-secrets;
  secretsFile = "${secretsDirectory}/secrets.yaml";
  homeDirectory = "/home/luke";
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    defaultSopsFile = "${secretsFile}";
    validateSopsFiles = false;

    age = {
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };

    secrets = {
      time_zone = {};
      domain_name = {};
      email_address = {};
      "jellyfin/api_key" = {};
    };

    templates = {
      "domainName".content = ''${config.sops.placeholder.domain_name}'';
    };
  };

  system.activationScripts.sopsSetAgeKeyOwnership = 
    let
      ageFolder = "${homeDirectory}/.config/sops/age";
      user = config.users.users.luke.name;
      group = config.users.users.luke.group;
    in
      ''
        mkdir -p ${ageFolder} || true
        chown -R ${user}:${group} ${homeDirectory}/.config
      '';
}