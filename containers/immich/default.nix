{ config, vars, ... }:
let
  # adjust to bump the version when required
  immichVersion = "v2.6.3";
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

  # TODO:
  # - clean up /db and /model-cache folders on the HDD
  # - clean up all but /db and /model-cache folders on the SSD
in {
  # Keep redis from complaining
  boot.kernel.sysctl = {
    "vm.overcommit_memory" = 1;
  };

  homelab.services.immich = {
    image = "ghcr.io/immich-app/immich-server:${immichVersion}";
    subdomain = "immich";
    port = 2283;
    publishPorts = [ "2283:2283" ];
    metricsPorts = [ 8081 8082 ];
    dirs = [
      immichRootDir
      immichHddDir
      immichExternalDir
      dbDir
      modelCacheDir
    ];
    volumes = [
      "${immichHddDir}:/data"
      "/etc/localtime:/etc/localtime:ro"
      # External Libraries - in the immich GUI, use `/Photos/*` as the folder path
      "${immichExternalDir}:/Photos"
    ];
    # image doesn't consume PUID/PGID
    user = null;
    env = {
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
    extraPodmanArgs = [
      "--device=/dev/dri:/dev/dri"
    ];
    extraContainerConfig = {
      dependsOn = [
        "immich_redis"
        "immich_db"
      ];
    };
    homepage = {
      group = "Media";
      name = "Immich";
      icon = "immich";
      description = "Photo Sync";
      widget = {
        type = "immich";
        url = "https://immich.${vars.domainName}";
        key = "{{HOMEPAGE_FILE_IMMICH_KEY}}";
        version = "2";
      };
    };
  };

  # Sidecars
  virtualisation.oci-containers.containers = {
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
}
