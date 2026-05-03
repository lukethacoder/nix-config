{ config, vars, pkgs, ... }:
let
  # adjust to bump the version when required
  albumzVersion = "v0.1.1";

  # albumz config root dir
  rootDir = "${vars.serviceConfigRoot}/albumz";

  dbName = "albumz";
  dbHostName = "albumz_db";
  dbDir = "${rootDir}/db";

  postgresUser = "admin";
  postgresPassword = "password";

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
            "3000:3000"
          ];
          environment = {
            TZ = vars.timeZone;
            DATABASE_URL = "postgresql://${postgresUser}:${postgresPassword}@${dbHostName}:5432/${dbName}";
            JWT_SECRET = "test123";
            ORIGIN = "albumz.${vars.domainName}";
            # LASTFM_API_KEY
            # SPOTIFY_CLIENT_ID
            # SPOTIFY_CLIENT_SECRET
          };
          # environmentFiles = [
          #   config.sops.templates."albumz-env".path
          # ];
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
            "5432:5432"
          ];
          volumes = [
            "${dbDir}:/var/lib/postgresql/data"
          ];
          # environmentFiles = [
          #   config.sops.templates."albumz-env".path
          # ];
          environment = {
            DB_DATA_LOCATION = "/var/lib/postgresql/data";
            POSTGRES_DB = dbName;
            POSTGRES_USER = postgresUser;
            POSTGRES_PASSWORD = postgresPassword;
          };
        };
      };
    };
  };
}
