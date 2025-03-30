{ pkgs, inputs, config, configVars, ... }:
let
  secretsDirectory = builtins.toString inputs.nix-secrets;
  secretsFile = "${secretsDirectory}/secrets.yaml";
  homeDirectory = "/home/luke";
  secrets = builtins.extraBuiltins.readSops "${inputs.nix-secrets}/secrets.nix.enc";
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  # system.activationScripts.sops-debug = ''
  #   echo "TEST LOG SOPS 2 ${secretsFile} ${secrets.time_zone}"
  # '';
  # system.activationScripts.sops-debug = ''
  #   echo "time_zone?"
  #   echo (cat ${config.sops.secrets."time_zone".path} | curl)
  # '';
  # ${builtins.toString secrets}
  # environment.etc."debug-sops".text = builtins.trace "TEST LOG SOPS ${builtins.toString secrets}" "N/A";

  sops = {
    defaultSopsFile = "${secretsFile}";
    validateSopsFiles = true;

    age = {
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };

    secrets = {
      time_zone = {};
      domain_name = {};
      email_address = {};
      "tailscale/otp" = {};
      # "tailscale/host_domain" = {};
      "duckdns/token" = {};
      "wireguard/endpoint_ip" = {};
      "wireguard/endpoint_port" = {};
      "wireguard/public_key" = {};
      "wireguard/private_key" = {};
      "wireguard/addresses" = {};
      "adguard/username" = {};
      "adguard/password" = {};
      "jellyfin/api_key" = {};
      "navidrome/username" = {};
      "navidrome/token" = {};
      "navidrome/salt" = {};
      "lastfm/api_key" = {};
      "lastfm/api_secret" = {};
      "immich/postgres_username" = {};
      "immich/postgres_password" = {};
      "immich/api_key" = {};
      samba_password = {};
    };

    templates = {
      "domainName".content = ''${config.sops.placeholder.domain_name}'';
      "navidrome-env".content = ''
        ND_LASTFM_APIKEY=${config.sops.placeholder."lastfm/api_key"}
        ND_LASTFM_SECRET=${config.sops.placeholder."lastfm/api_secret"}
      '';
    };
  };

  system.activationScripts.sopsSetAgeKeyOwnership = 
    let
      ageFolder = "${homeDirectory}/.config/sops/age";
      user = config.users.users.luke.name;
      group = config.users.users.luke.group;
    in
      ''
        echo "navidrome-env: ${config.sops.templates."navidrome-env".path}"
        mkdir -p ${ageFolder} || true
        chown -R ${user}:${group} ${homeDirectory}/.config
      '';
}