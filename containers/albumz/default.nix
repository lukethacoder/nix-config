{ config, vars, pkgs, ... }:
let
  # adjust to bump the version when required
  albumzVersion = "0.1.1";

  # albumz config root dir
  rootDir = "${vars.serviceConfigRoot}/albumz";

  dbName = "albumz";
  dbDir = "${rootDir}/db";

  directories = [
    rootDir
    dbDir
  ];
in {
  systemd.tmpfiles.rules = map (x: "d ${x} 0775 share share - -") directories;

  virtualisation = {
    oci-containers = {
      containers = {
        albumz = {
          autoStart = true;
          image = "ghcr.io/lukethacoder/albumz:${albumzVersion}";
          ports = [
            "3434:3000"
          ];
          environment = {
            TZ = vars.timeZone;
            ORIGIN = "https://albumz.${vars.domainName}";
          };
          environmentFiles = [
            config.sops.templates."albumz-env".path
          ];
          extraOptions = [
            "-l=traefik.enable=true"
            "-l=traefik.http.routers.albumz.rule=Host(`albumz.${vars.domainName}`)"
            "-l=traefik.http.services.albumz.loadbalancer.server.port=3000"
            "-l=homepage.group=Media"
            "-l=homepage.name=albumz"
            "-l=homepage.href=https://albumz.${vars.domainName}"
            "-l=homepage.description=Album tracker"
            "-l=homepage.widget.url=https://albumz.${vars.domainName}"
            "-l=homepage.widget.version=2"
          ];
          dependsOn = [
            "albumz_db"
          ];
        };

        albumz_db = {
          autoStart = true;
          image = "postgres:16-alpine";
          ports = [
            "5433:5432"
          ];
          volumes = [
            "${dbDir}:/var/lib/postgresql/data"
          ];
          environmentFiles = [
            config.sops.templates."albumz-env".path
          ];
          environment = {
            DB_DATA_LOCATION = "/var/lib/postgresql/data";
            POSTGRES_DB = dbName;
          };
        };
      };
    };
  };
}
