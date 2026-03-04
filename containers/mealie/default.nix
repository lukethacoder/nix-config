{ config, vars, pkgs, ... }:
let 
  directories = [
    "${vars.serviceConfigRoot}/mealie"
  ];
  VERSION = "v3.11.0";
in {
  systemd.tmpfiles.rules = map (x: "d ${x} 0775 share share - -") directories;

  system.userActivationScripts.mealie-data.text = ''
    mkdir -p ${vars.serviceConfigRoot}/mealie
  '';

  virtualisation.oci-containers = {
    containers = {
      mealie = {
        image = "ghcr.io/mealie-recipes/mealie:${VERSION}";
        autoStart = true;
        ports = [ "9925:9000" ];
        volumes = [
          "${vars.serviceConfigRoot}/mealie:/app/data"
        ];
        environment = {
          TZ = config.sops.secrets.time_zone.path;
          PUID = "1000";
          PGID = "1000";
          BASE_URL = "https://cook.${vars.domainName}";
        };
        extraOptions = [
          "--pull=newer"
          "-l=traefik.enable=true"
          "-l=traefik.http.routers.mealie.rule=Host(`cook.${vars.domainName}`)"
          "-l=traefik.http.services.mealie.loadbalancer.server.port=9000"
          "-l=homepage.group=Media"
          "-l=homepage.name=Mealie"
          "-l=homepage.icon=mealie.svg"
          "-l=homepage.href=https://cook.${vars.domainName}"
          "-l=homepage.description=Recipes"
          "-l=homepage.widget.type=mealie"
          "-l=homepage.widget.token={{HOMEPAGE_FILE_MEALIE_TOKEN}}"
          "-l=homepage.widget.version=2"
          "-l=homepage.widget.url=https://cook.${vars.domainName}"
        ];
      };
    };
  };
}