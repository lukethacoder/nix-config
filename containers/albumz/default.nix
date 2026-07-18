{ config, vars, ... }:
let
  # adjust to bump the version when required
  albumzVersion = "0.1.1";

  # albumz config root dir
  rootDir = "${vars.serviceConfigRoot}/albumz";

  dbName = "albumz";
  dbDir = "${rootDir}/db";
in {
  homelab.services.albumz = {
    image = "ghcr.io/lukethacoder/albumz:${albumzVersion}";
    subdomain = "albumz";
    port = 3000;
    publishPorts = [
      "3434:3000"
    ];
    dirs = [
      rootDir
      dbDir
    ];
    # image doesn't consume PUID/PGID
    user = null;
    env = {
      ORIGIN = "https://albumz.${vars.domainName}";
    };
    environmentFiles = [
      config.sops.templates."albumz-env".path
    ];
    extraContainerConfig = {
      dependsOn = [
        "albumz-db"
      ];
    };
    homepage = {
      group = "Media";
      name = "albumz";
      description = "Album tracker";
      widget = {
        url = "https://albumz.${vars.domainName}";
        version = "2";
      };
    };
  };

  # Sidecar
  virtualisation.oci-containers.containers.albumz-db = {
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
}
