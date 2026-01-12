{ config, vars, pkgs, ... }:
let
  directories = [
    "${vars.serviceConfigRoot}/miniflux"
  ];
in
{
  systemd.tmpfiles.rules = map (x: "d ${x} 0775 share share - -") directories;

  virtualisation.oci-containers = {
    containers = {
      miniflux = {
        image = "miniflux/miniflux:2.2.16";
        autoStart = true;
        dependsOn = [
          "miniflux-db"
        ];
        extraOptions = [
          "--pull=newer"
          "-l=traefik.enable=true"
          "-l=traefik.http.routers.miniflux.rule=Host(`miniflux.${vars.domainName}`)"
          "-l=traefik.http.services.miniflux.loadbalancer.server.port=8080"

          "-l=homepage.group=Services"
          "-l=homepage.name=miniflux"
          "-l=homepage.icon=miniflux"
          "-l=homepage.href=https://miniflux.${vars.domainName}"
          "-l=homepage.description=RSS"
          "-l=homepage.widget.type=miniflux"
          "-l=homepage.widget.password=test"
          "-l=homepage.widget.url=https://miniflux.${vars.domainName}"
        ];
        environment = {
          TZ = vars.timeZone;
          BASE_URL = "https://miniflux.${vars.domainName}";
          DATABASE_URL = "postgres://miniflux:test@miniflux-db/miniflux?sslmode=disable";
          RUN_MIGRATIONS = "1";
          CREATE_ADMIN = "1";
          ADMIN_USERNAME = "admin";
          ADMIN_PASSWORD = "test123";
          FETCH_YOUTUBE_WATCH_TIME = "1";
          METRICS_COLLECTOR = "1";
          METRICS_ALLOWED_NETWORKS = "0.0.0.0/0";
        };
      };
      miniflux-db = {
        image = "postgres:18";
        autoStart = true;
        volumes = [
          "${vars.serviceConfigRoot}/miniflux:/var/lib/postgresql"
        ];
        environment = {
          TZ = vars.timeZone;
          POSTGRES_USER = "miniflux";
          POSTGRES_PASSWORD = "test";
          POSTGRES_DB = "miniflux";
        };
      };
    };
  };
}
