{ config, vars, pkgs, ... }:
let directories = [
  "${vars.serviceConfigRoot}/navidrome"
  "${vars.serviceConfigRoot}/navidrome-mixes"
  "${vars.mainArray}/Media/Music"
];
in {
  systemd.tmpfiles.rules = map (x: "d ${x} 0775 share share - -") directories;

  system.userActivationScripts.navidrome-data.text = ''
    mkdir -p ${vars.serviceConfigRoot}/navidrome \
      ${vars.mainArray}/Media/Music/Music \
      ${vars.serviceConfigRoot}/navidrome-mixes \
      ${vars.mainArray}/Media/Music/Mixes
  '';

  virtualisation.oci-containers = {
    containers = {
      navidrome = {
        image = "deluan/navidrome:0.55.0";
        autoStart = true;
        ports = [ "4533:4533" ];
        volumes = [
          "${vars.serviceConfigRoot}/navidrome:/data"
          "${vars.mainArray}/Media/Music/Music:/music:ro"
        ];
        environment = {
          TZ = config.sops.secrets.time_zone.path;
          PUID = "1000";
          PGID = "1000";
          ND_SCANSCHEDULE = "1h";
          ND_LOGLEVEL = "info";
          ND_SESSIONTIMEOUT = "24h";
          ND_BASEURL = "http://navidrome.${builtins.readFile config.sops.secrets.domain_name.path}";
          ND_LASTFM_ENABLED = "true";
          ND_LASTFM_APIKEY = builtins.readFile config.sops.secrets."lastfm/api_key".path;
          ND_LASTFM_SECRET = builtins.readFile config.sops.secrets."lastfm/api_secret".path;
        };
        extraOptions = [
          "--pull=newer"
          "-l=traefik.enable=true"
          "-l=traefik.http.routers.navidrome.rule=Host(`navidrome.${builtins.readFile config.sops.secrets.domain_name.path}`)"
          "-l=traefik.http.services.navidrome.loadbalancer.server.port=4533"
          "-l=homepage.group=Media"
          "-l=homepage.name=Navidrome"
          "-l=homepage.icon=navidrome.svg"
          "-l=homepage.href=https://navidrome.${builtins.readFile config.sops.secrets.domain_name.path}"
          "-l=homepage.description=Media player"
          "-l=homepage.widget.type=navidrome"
          "-l=homepage.widget.user={{HOMEPAGE_FILE_NAVIDROME_USERNAME}}"
          "-l=homepage.widget.token={{HOMEPAGE_FILE_NAVIDROME_TOKEN}}"
          "-l=homepage.widget.salt={{HOMEPAGE_FILE_NAVIDROME_SALT}}"
          "-l=homepage.widget.url=https://navidrome.${builtins.readFile config.sops.secrets.domain_name.path}"
        ];
      };
      # Separate instance purely for DJ Mixes
      navidrome_mixes = {
        image = "deluan/navidrome:0.55.0";
        autoStart = true;
        ports = [ "4534:4533" ];
        volumes = [
          "${vars.serviceConfigRoot}/navidrome-mixes:/data"
          "${vars.mainArray}/Media/Music/Mixes:/music:ro"
        ];
        environment = {
          TZ = config.sops.secrets.time_zone.path;
          PUID = "1000";
          PGID = "1000";
          ND_SCANSCHEDULE = "1h";
          ND_LOGLEVEL = "info";
          ND_SESSIONTIMEOUT = "24h";
          ND_BASEURL = "http://mixes.${builtins.readFile config.sops.secrets.domain_name.path}";
          ND_LASTFM_ENABLED = "true";
          ND_LASTFM_APIKEY = builtins.readFile config.sops.secrets."lastfm/api_key".path;
          ND_LASTFM_SECRET = builtins.readFile config.sops.secrets."lastfm/api_secret".path;
        };
        extraOptions = [
          "--pull=newer"
          "-l=traefik.enable=true"
          "-l=traefik.http.routers.navidromemixes.rule=Host(`mixes.${builtins.readFile config.sops.secrets.domain_name.path}`)"
          "-l=traefik.http.services.navidromemixes.loadbalancer.server.port=4533"
          "-l=homepage.group=Media"
          "-l=homepage.name=Navidrome Mixes"
          "-l=homepage.icon=https://simpleicons.org/icons/pioneerdj.svg"
          "-l=homepage.href=https://mixes.${builtins.readFile config.sops.secrets.domain_name.path}"
          "-l=homepage.description=Media player"
          "-l=homepage.widget.type=navidrome"
          "-l=homepage.widget.user={{HOMEPAGE_FILE_NAVIDROME_USERNAME}}"
          "-l=homepage.widget.token={{HOMEPAGE_FILE_NAVIDROME_TOKEN}}"
          "-l=homepage.widget.salt={{HOMEPAGE_FILE_NAVIDROME_SALT}}"
          "-l=homepage.widget.url=https://mixes.${builtins.readFile config.sops.secrets.domain_name.path}"
        ];
      };
    };
  };
}