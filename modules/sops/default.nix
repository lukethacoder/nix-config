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
      "cloudflare/dns_api_key" = {};
      "wireguard/endpoint_ip" = {};
      "wireguard/endpoint_port" = {};
      "wireguard/public_key" = {};
      "wireguard/private_key" = {};
      "wireguard/addresses" = {};
      "adguard/username" = {};
      "adguard/password" = {};
      "qbittorrent/username" = {};
      "qbittorrent/password" = {};
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
      # DUCKDNS_TOKEN=${config.sops.placeholder."duckdns/token"}
      "traefik-env".content = ''
        CF_DNS_API_TOKEN=${config.sops.placeholder."cloudflare/dns_api_key"}
      '';
      "immich-env".content = ''
        DB_USERNAME=${config.sops.placeholder."immich/postgres_username"}
        DB_PASSWORD=${config.sops.placeholder."immich/postgres_password"}
        POSTGRES_USER=${config.sops.placeholder."immich/postgres_username"}
        POSTGRES_PASSWORD=${config.sops.placeholder."immich/postgres_password"}
        IMMICH_API_KEY=${config.sops.placeholder."immich/api_key"}
      '';
      "navidrome-env".content = ''
        ND_LASTFM_APIKEY=${config.sops.placeholder."lastfm/api_key"}
        ND_LASTFM_SECRET=${config.sops.placeholder."lastfm/api_secret"}
      '';
      "wireguard-env".content = ''
        WIREGUARD_ENDPOINT_IP=${config.sops.placeholder."wireguard/endpoint_ip"}
        WIREGUARD_ENDPOINT_PORT=${config.sops.placeholder."wireguard/endpoint_port"}
        WIREGUARD_PUBLIC_KEY=${config.sops.placeholder."wireguard/public_key"}
        WIREGUARD_PRIVATE_KEY=${config.sops.placeholder."wireguard/private_key"}
        WIREGUARD_ADDRESSES=${config.sops.placeholder."wireguard/addresses"}
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
        mkdir -p ${ageFolder} || true
        chown -R ${user}:${group} ${homeDirectory}/.config
      '';
}