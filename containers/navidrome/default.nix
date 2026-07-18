{ config, vars, ... }:
let
  VERSION = "0.63.1";
  sharedEnv = {
    ND_SCANSCHEDULE = "1h";
    ND_LOGLEVEL = "info";
    ND_SESSIONTIMEOUT = "24h";
    ND_LASTFM_ENABLED = "true";
  };
in {
  homelab.services.navidrome = {
    image = "deluan/navidrome:${VERSION}";
    subdomain = "navidrome";
    port = 4533;
    publishPorts = [ "4533:4533" ];
    dirs = [
      "${vars.serviceConfigRoot}/navidrome"
      "${vars.mainArray}/Media/Music"
      "${vars.mainArray}/Media/Music/Music"
    ];
    volumes = [
      "${vars.serviceConfigRoot}/navidrome:/data"
      "${vars.mainArray}/Media/Music/Music:/music:ro"
    ];
    # data on disk is owned by uid 1000; normalize to the share identity later
    user = { uid = 1000; gid = 1000; };
    env = sharedEnv // {
      ND_BASEURL = "http://navidrome.${vars.domainName}";
      ND_PROMETHEUS_ENABLED = "true";
    };
    environmentFiles = [
      config.sops.templates."navidrome-env".path
    ];
    homepage = {
      group = "Media";
      name = "Navidrome";
      icon = "navidrome.svg";
      description = "Media player";
      widget = {
        type = "navidrome";
        user = "{{HOMEPAGE_FILE_NAVIDROME_USERNAME}}";
        token = "{{HOMEPAGE_FILE_NAVIDROME_TOKEN}}";
        salt = "{{HOMEPAGE_FILE_NAVIDROME_SALT}}";
        url = "https://navidrome.${vars.domainName}";
      };
    };
  };

  # Separate instance purely for DJ Mixes
  # TODO: multi libraries are now supported - migrate when possible
  homelab.services.navidrome_mixes = {
    image = "deluan/navidrome:${VERSION}";
    subdomain = "mixes";
    port = 4533;
    publishPorts = [ "4534:4533" ];
    dirs = [
      "${vars.serviceConfigRoot}/navidrome-mixes"
      "${vars.mainArray}/Media/Music/Mixes"
    ];
    volumes = [
      "${vars.serviceConfigRoot}/navidrome-mixes:/data"
      "${vars.mainArray}/Media/Music/Mixes:/music:ro"
    ];
    user = { uid = 1000; gid = 1000; };
    env = sharedEnv // {
      ND_BASEURL = "http://mixes.${vars.domainName}";
      # ND_LASTFM_APIKEY = config.sops.secrets."lastfm/api_key".path;
      # ND_LASTFM_SECRET = config.sops.secrets."lastfm/api_secret".path;
    };
    environmentFiles = [
      config.sops.templates."navidrome-env".path
    ];
    homepage = {
      group = "Media";
      name = "Navidrome Mixes";
      icon = "https://simpleicons.org/icons/pioneerdj.svg";
      description = "Media player";
      widget = {
        type = "navidrome";
        user = "{{HOMEPAGE_FILE_NAVIDROME_USERNAME}}";
        token = "{{HOMEPAGE_FILE_NAVIDROME_TOKEN}}";
        salt = "{{HOMEPAGE_FILE_NAVIDROME_SALT}}";
        url = "https://mixes.${vars.domainName}";
      };
    };
  };
}
