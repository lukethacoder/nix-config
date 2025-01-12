{ config, vars, pkgs, ... }:
let 
  directories = [
    "${vars.serviceConfigRoot}/immich"
    "${vars.serviceConfigRoot}/immich/config"
    "${vars.mainArray}/Photos/immich"
    "${vars.mainArray}/Photos/immich/encoded-video"
  ];
  db_name = "immich";
in {

  # users = {
  #   groups.share = {
  #     gid = 993;
  #   };
  #   users.share = {
  #     uid = 994;
  #     isSystemUser = true;
  #     group = "share";
  #   };
  # };

  system.userActivationScripts.immich-data.text = ''
    mkdir -p ${vars.serviceConfigRoot}/immich \
      ${vars.serviceConfigRoot}/immich/config \
      ${vars.serviceConfigRoot}/immich/pgdata \
      ${vars.mainArray}/Photos/immich \
      ${vars.mainArray}/Photos/immich/encoded-video
  '';

  # # not ideal, but doesn't seem to let windows have write access without 0777 :(
  # system.activationScripts.giveImmichShareUserAccessToFolders = 
  #   let
  #     user = config.users.users.share.name;
  #     group = config.users.users.share.group;
  #   in
  #     ''
  #       chown -R ${config.users.users.share.name}:${config.users.users.share.group} /mnt/user/Photos
  #       chmod -R 0777 /mnt/user/Photos
  #     '';
  
  systemd.tmpfiles.rules = map (x: "d ${x} 0775 share share - -") directories;

  system.activationScripts.init-immich-network = let
    backend = config.virtualisation.oci-containers.backend;
    backendBin = "${pkgs.${backend}}/bin/${backend}";
  in ''
      # immich-net network
      check=$(${backendBin} network ls | grep "immich-net" || true)
      if [ -z "$check" ]; then
        ${backendBin} network create immich-net
      else
        echo "immich-net already exists in docker"
      fi
  '';

  # Keep redis from complaining
  boot.kernel.sysctl = {
    "vm.overcommit_memory" = 1;
  };

  # Immich
  virtualisation = {
    oci-containers = {
      containers = {
        immich = {
          autoStart = true;
          image = "ghcr.io/imagegenius/immich:latest";
          volumes = [
            "${vars.serviceConfigRoot}/immich/config:/config"
            "${vars.serviceConfigRoot}/immich/config/machine-learning:/config/machine-learning"
            "${vars.mainArray}/Photos/immich:/photos"
            "${vars.mainArray}/Photos/immich/encoded-video/.immich:/photos/encoded-video/.immich"
          ];
          ports = [ "2283:8080" ];
          environment = {
            PUID = "0";
            PGID = "0";
            TZ = config.sops.secrets.time_zone.path;
            
            # using '--network="immich-net"' means using the container name doesn't resolve correctly 
            DB_HOSTNAME = "10.89.0.1"; # "immich_postgres"
            DB_USERNAME = "postgres";
            DB_PASSWORD = "postgres";
            DB_DATABASE_NAME = db_name;
            
            REDIS_HOSTNAME = "10.89.0.1";
          };
          extraOptions = [
            "--network=immich-net"
            "--device=/dev/dri:/dev/dri"
            # "--gpus=all"

            "-l=traefik.enable=true"
            "-l=traefik.http.routers.immich.rule=Host(`immich.${builtins.readFile config.sops.secrets.domain_name.path}`)"
            "-l=traefik.http.services.immich.loadbalancer.server.url=http://10.89.0.1:2283"
            "-l=homepage.group=Media"
            "-l=homepage.name=Immich"
            "-l=homepage.icon=immich"
            "-l=homepage.href=https://immich.${builtins.readFile config.sops.secrets.domain_name.path}"
            "-l=homepage.description=Photo Sync"
            "-l=homepage.widget.type=immich"
            "-l=homepage.widget.url=https://immich.${builtins.readFile config.sops.secrets.domain_name.path}"
            # "-l=homepage.widget.user={{HOMEPAGE_FILE_NAVIDROME_USERNAME}}"
            # "-l=homepage.widget.token={{HOMEPAGE_FILE_NAVIDROME_TOKEN}}"
            # "-l=homepage.widget.salt={{HOMEPAGE_FILE_NAVIDROME_SALT}}"
          ];
        };

        immich_redis = {
          autoStart = true;
          image = "redis";
          ports = [
            "6379:6379"
          ];
          extraOptions = [
            "--network=immich-net"
          ];
        };

        immich_postgres = {
          autoStart = true;
          image = "tensorchord/pgvecto-rs:pg16-v0.2.1";
          ports = [
            "5432:5432"
          ];
          volumes = [
            "${vars.serviceConfigRoot}/immich/pgdata:/var/lib/postgresql/data"
          ];
          environment = {
            POSTGRES_USER = "postgres";
            POSTGRES_PASSWORD = "postgres";
            POSTGRES_DB = db_name;
          };
          extraOptions = [
            "--network=immich-net"
          ];
        };
      };
    };
  };
}