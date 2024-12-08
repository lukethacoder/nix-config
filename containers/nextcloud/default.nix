{ config, pkgs, vars, ... }:

let
  nextcloudDataDir = "${vars.serviceConfigRoot}/nextcloud-data";
  nextcloudDbDir = "${vars.serviceConfigRoot}/nextcloud-db";
  nextcloudDbDirPostgres = "${vars.serviceConfigRoot}/nextcloud-db-postgres";
in
{
  system.activationScripts.nextcloudFolders = ''
    mkdir -p ${nextcloudDataDir}
    mkdir -p ${nextcloudDbDir}
    mkdir -p ${nextcloudDbDirPostgres}
  '';

  # Ensure necessary directories exist
  systemd.tmpfiles.rules = [
    "d ${nextcloudDataDir} 0755 nextcloud nextcloud -"
    "d ${nextcloudDbDir} 0755 nextcloud nextcloud -"
    "d ${nextcloudDbDirPostgres} 0755 nextcloud nextcloud -"
  ];

  systemd.user.extraConfig = "DefaultTimeoutStopSec=30s";

  system.activationScripts.nextcloudNetwork = 
    let
      backend = config.virtualisation.oci-containers.backend;
      backendBin = "${pkgs.${backend}}/bin/${backend}";
    in
    ''
      ${backendBin} network create nextcloud-net --subnet 172.20.0.0/16 || true
    '';

  # User and group for Nextcloud
  # users.users.nextcloud = {
  #   isSystemUser = true;
  #   home = nextcloudDataDir;
  #   group = "nextcloud";
  # };
  # users.groups.nextcloud = {};

  # security.acme = {
  #   acceptTerms = true;
  #   defaults = {
  #     email = builtins.readFile config.sops.secrets.email_address.path;
  #   };
  # };
  
  services = {
    # nginx.virtualHosts = {
    #   "cloud.why.duckdns.org" = {
    #     forceSSL = true;
    #     enableACME = true;
    #   };

    #   "onlyoffice.why.duckdns.org" = {
    #     forceSSL = true;
    #     enableACME = true;
    #   };
    # };

    nginx.virtualHosts."localhost".listen = [
      {
        addr = "127.0.0.1";
        port = 8080;
      }
    ];

    nextcloud = {
      enable = true;
      hostName = "localhost";
      https = false;

       # Need to manually increment with every major upgrade.
      package = pkgs.nextcloud29;

      # Let NixOS install and configure the database automatically.
      database.createLocally = true;

      # Let NixOS install and configure Redis caching automatically.
      configureRedis = true;

      # Increase the maximum file upload size to avoid problems uploading videos.
      maxUploadSize = "16G";

      autoUpdateApps.enable = true;
      extraAppsEnable = true;
      extraApps = with config.services.nextcloud.package.packages.apps; {
        # List of apps we want to install and are already packaged in
        # https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/nextcloud/packages/nextcloud-apps.json
        # inherit calendar contacts mail notes onlyoffice tasks;
        inherit onlyoffice;

        # Custom app installation example.
        # cookbook = pkgs.fetchNextcloudApp rec {
        #   url =
        #     "https://github.com/nextcloud/cookbook/releases/download/v0.10.2/Cookbook-0.10.2.tar.gz";
        #   sha256 = "sha256-XgBwUr26qW6wvqhrnhhhhcN4wkI+eXDHnNSm1HDbP6M=";
        # };
      };

      config = {
        dbtype = "pgsql";
        adminuser = "admin";
        adminpassFile = "${vars.serviceConfigRoot}/nextcloud-password.txt";
      };

      settings = {
        overwriteprotocol = "https";
        default_phone_region = "PT";
      };
    };

    onlyoffice = {
      enable = true;
      # hostname = "onlyoffice.lukethacoder.duckdns.org";
    };
  };

}