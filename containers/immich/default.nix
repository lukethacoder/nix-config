{ config, vars, pkgs, ... }:
let directories = [
  "${vars.serviceConfigRoot}/immich"
  "${vars.mainArray}/Photos/immich"
];
in {
  systemd.tmpfiles.rules = map (x: "d ${x} 0775 share share - -") directories;

  system.userActivationScripts.navidrome-data.text = ''
    mkdir -p ${vars.serviceConfigRoot}/immich \
      ${vars.serviceConfigRoot}/immich/config \
      ${vars.serviceConfigRoot}/immich/pgdata
  '';

  # systemd.services.init-filerun-network-and-files = {
  #   description = "Create the network bridge for Immich.";
  #   after = [ "network.target" ];
  #   wantedBy = [ "multi-user.target" ];
    
  #   serviceConfig.Type = "oneshot";
  #   script = let dockercli = "${config.virtualisation.docker.package}/bin/docker";
  #     in ''
  #       # immich-net network
  #       check=$(${dockercli} network ls | grep "immich-net" || true)
  #       if [ -z "$check" ]; then
  #         ${dockercli} network create immich-net
  #       else
  #         echo "immich-net already exists in docker"
  #       fi
  #     '';
  # };

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
          ];
          ports = [ "2283:8080" ];
          environment = {
            PUID = "1000";
            PGID = "1000";
            TZ = config.sops.secrets.time_zone.path;
            DB_HOSTNAME = "immich_postgres";
            DB_USERNAME = "postgres";
            DB_PASSWORD = "postgres";
            DB_DATABASE_NAME = "immich";
            REDIS_HOSTNAME = "immich_redis";
          };
          extraOptions = [
            "--network=immich-net"
            # "--gpus=all"

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
            POSTGRES_DB = "immich_postgres";
          };
          extraOptions = [
            "--network=immich-net"
          ];
        };
      };
    };
  };
}