{ config, vars, pkgs, ... }:
let
  # adjust to bump the version when required
  immichVersion = "v2.6.1";
  # bulk of the config lives here
  immichHddDir = "${vars.mainArray}/immich";

  # External Library root path
  immichExternalDir = "${vars.mainArray}/Photos";

  # Immich config root dir - stores the /db and /model-cache files
  immichRootDir = "${vars.serviceConfigRoot}/immich";

  dbName = "immich";
  dbHostName = "immich_db";
  redisHostName = "immich_redis";
  dbDir = "${immichRootDir}/db";
  modelCacheDir = "${immichRootDir}/model-cache";

  containerUploadDir = "/usr/src/app/upload";

  # TODO:
  # - clean up /db and /model-cache folders on the HDD
  # - clean up all but /db and /model-cache folders on the SSD

  directories = [
    immichRootDir
    immichHddDir
    "${vars.mainArray}/Photos"
    dbDir
    modelCacheDir
  ];
in {
  systemd.tmpfiles.rules = map (x: "d ${x} 0775 share share - -") directories;

  # Keep redis from complaining
  boot.kernel.sysctl = {
    "vm.overcommit_memory" = 1;
  };

  # Immich
  virtualisation = {
    oci-containers = {
      containers = {
        immich_server = {
          autoStart = true;
          image = "ghcr.io/immich-app/immich-server:${immichVersion}";
          ports = [
            "2283:2283" # Main Appplication
            "8081:8081" # API Metrics
            "8082:8082" # Microservice Metrics
          ];
          volumes = [
            "${immichHddDir}:/data"
            "/etc/localtime:/etc/localtime:ro"
            # External Libraries - in the immich GUI, use `/Photos/*` as the folder path
            "${immichExternalDir}:/Photos"
          ];
          environment = {
            TZ = vars.timeZone;
            IMMICH_VERSION = immichVersion;
            DB_HOSTNAME = dbHostName;
            REDIS_HOSTNAME = redisHostName;
            DB_DATABASE_NAME = dbName;
            IMMICH_TELEMETRY_INCLUDE = "all";
            IMMICH_LOG_FORMAT = "json";
          };
          environmentFiles = [
            config.sops.templates."immich-env".path
          ];
          extraOptions = [
            # "--network=immich-net"
            "--device=/dev/dri:/dev/dri"

            "-l=traefik.enable=true"
            "-l=traefik.http.routers.immich.rule=Host(`immich.${vars.domainName}`)"
            "-l=traefik.http.services.immich.loadbalancer.server.port=2283"
            "-l=homepage.group=Media"
            "-l=homepage.name=Immich"
            "-l=homepage.icon=immich"
            "-l=homepage.href=https://immich.${vars.domainName}"
            "-l=homepage.description=Photo Sync"
            "-l=homepage.widget.type=immich"
            "-l=homepage.widget.url=https://immich.${vars.domainName}"
            "-l=homepage.widget.key={{HOMEPAGE_FILE_IMMICH_KEY}}"
            "-l=homepage.widget.version=2"
          ];
          dependsOn = [
            "immich_redis"
            "immich_db"
          ];
        };
        # NOTE: this container name must match in Machine Learning settings (e.g. "http://immich_machine_learning:3003")
        immich_machine_learning = {
          autoStart = true;
          image = "ghcr.io/immich-app/immich-machine-learning:${immichVersion}";
          ports = [
            "3003:3003"
          ];
          volumes = [
            "${modelCacheDir}:/cache"
          ];
          environment = {
            IMMICH_VERSION = immichVersion;
          };
          extraOptions = [
            "--pull=newer"
            "--device=/dev/dri:/dev/dri"
          ];
        };
        immich_redis = {
          autoStart = true;
          image = "docker.io/valkey/valkey:9";
        };

        immich_db = {
          autoStart = true;
          image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0";
          ports = [
            "5432:5432"
          ];
          volumes = [
            "${dbDir}:/var/lib/postgresql/data"
          ];
          environmentFiles = [
            config.sops.templates."immich-env".path
          ];
          environment = {
            DB_DATA_LOCATION = "/var/lib/postgresql/data";
            POSTGRES_DB = dbName;
            POSTGRES_INITDB_ARGS = "--data-checksums";
            # Uncomment if not using an SSD
            # DB_STORAGE_TYPE = "HDD";
          };
        };
      };
    };
  };
}
