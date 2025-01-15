{ config, vars, pkgs, ... }:
let 
  immichVersion = "release";
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

  # system.activationScripts.init-immich-network = let
  #   backend = config.virtualisation.oci-containers.backend;
  #   backendBin = "${pkgs.${backend}}/bin/${backend}";
  # in ''
  #     # immich-net network
  #     check=$(${backendBin} network ls | grep "immich-net" || true)
  #     if [ -z "$check" ]; then
  #       ${backendBin} network create immich-net
  #     else
  #       echo "immich-net already exists in docker"
  #     fi
  # '';

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
            DB_USERNAME = builtins.readFile config.sops.secrets."immich/postgres_username".path;
            DB_PASSWORD = builtins.readFile config.sops.secrets."immich/postgres_password".path;
            DB_DATABASE_NAME = dbName;
          };
          extraOptions = [
            # "--network=immich-net"
            "--device=/dev/dri:/dev/dri"

            "-l=traefik.enable=true"
            "-l=traefik.http.routers.immich.rule=Host(`immich.${builtins.readFile config.sops.secrets.domain_name.path}`)"
            "-l=traefik.http.services.immich.loadbalancer.server.port=2283"
            "-l=homepage.group=Media"
            "-l=homepage.name=Immich"
            "-l=homepage.icon=immich"
            "-l=homepage.href=https://immich.${builtins.readFile config.sops.secrets.domain_name.path}"
            "-l=homepage.description=Photo Sync"
            "-l=homepage.widget.type=immich"
            "-l=homepage.widget.url=https://immich.${builtins.readFile config.sops.secrets.domain_name.path}"
            "-l=homepage.widget.key=${builtins.readFile config.sops.secrets."immich/api_key".path}"
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
            POSTGRES_USER = builtins.readFile config.sops.secrets."immich/postgres_username".path;
            POSTGRES_PASSWORD = builtins.readFile config.sops.secrets."immich/postgres_password".path;
            POSTGRES_DB = dbName;
          };
        };
      };
    };
  };
}