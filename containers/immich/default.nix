{ config, vars, pkgs, ... }:
let 
  # adjust to bump the version when required
  immichVersion = "v1.130.3";
  immichPhotosDir = "${vars.mainArray}/Photos/immich";
  immichRootDir = "${vars.serviceConfigRoot}/immich";

  dbName = "immich";
  dbHostName = "immich_db";
  redisHostName = "immich_redis";
  dbDir = "${immichRootDir}/db";

  directories = [
    immichRootDir
    immichPhotosDir
    "${vars.mainArray}/Photos"
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
            "2283:2283"
          ];
          volumes = [
            "${immichPhotosDir}:/usr/src/app/upload"
            "/etc/localtime:/etc/localtime:ro"
            # External Libraries
            "${vars.mainArray}/Photos:/Photos"
          ];
          environment = {
            IMMICH_VERSION = immichVersion;
            DB_HOSTNAME = dbHostName;
            REDIS_HOSTNAME = redisHostName;
            DB_DATABASE_NAME = dbName;
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
          image = "ghcr.io/immich-app/immich-machine-learning:${immichVersion}";
          ports = [
            "3003:3003"
          ];
          volumes = [
            "${immichRootDir}/model-cache:/cache"
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
          image = "redis";
          ports = [
            "6379:6379"
          ];
        };

        immich_db = {
          autoStart = true;
          image = "tensorchord/pgvecto-rs:pg14-v0.2.0";
          ports = [
            "5432:5432"
          ];
          volumes = [
            "${dbDir}:/var/lib/postgresql/data"
          ];
          environment = {
            POSTGRES_DB = dbName;
          };
        };
      };
    };
  };
}