{ config, pkgs, vars, ... }:

let
  nextcloudDataDir = "${vars.serviceConfigRoot}/nextcloud-data";
  nextcloudDbDir = "${vars.serviceConfigRoot}/nextcloud-db";
in
{
  system.activationScripts.nextcloudFolders = ''
    mkdir -p ${nextcloudDataDir}
    mkdir -p ${nextcloudDbDir}
  '';

  # Ensure necessary directories exist
  systemd.tmpfiles.rules = [
    "d ${nextcloudDataDir} 0755 nextcloud nextcloud -"
    "d ${nextcloudDbDir} 0755 nextcloud nextcloud -"
  ];

  systemd.user.extraConfig = "DefaultTimeoutStopSec=30s";

  system.activationScripts.nextcloudNetwork = 
    let
      backend = config.virtualisation.oci-containers.backend;
      backendBin = "${pkgs.${backend}}/bin/${backend}";
    in
    ''
      ${backendBin} network create nextcloud-net --subnet 172.20.0.0/16 || true
    '';

  # User and group for Nextcloud
  users.users.nextcloud = {
    isSystemUser = true;
    home = nextcloudDataDir;
    group = "nextcloud";
  };
  users.groups.nextcloud = {};

  virtualisation.oci-containers = {
    containers = {
      nextcloud-aio-mastercontainer = {
        image = "nextcloud/all-in-one:latest";
        autoStart = true;
        volumes = [
          # "${nextcloudDataDir}:/mnt/docker-aio-config"
          "nextcloud_aio_mastercontainer:/mnt/docker-aio-config"
          "/var/run/podman/podman.sock:/var/run/docker.sock:ro"
        ];
        ports = [
          "8347:80"
          "8348:8080"
          "8443:8443"
        ];
        environment = {
          TZ = vars.timeZone;
        };
        extraOptions = [
          "--network=nextcloud-net"
        ];
      };
      # nextcloud_db_02 = {
      #   image = "postgres:17.2";
      #   autoStart = true;
      #   volumes = [
      #     "${nextcloudDbDirPostgres}:/var/lib/postgresql/data"
      #   ];
      #   ports = [
      #     "5433:5432"
      #   ];
      #   cmd = [
      #     "--restart=always"
      #     "--restart-delay=20s"
      #     # MariaDB fix
      #     # "--innodb-read-only-compressed=OFF"
      #     # "--transaction-isolation=READ-COMMITTED"
      #     # "--log-bin=binlog"
      #     # "--binlog-format=ROW"
      #   ];
      #   environment = {
      #     POSTGRES_DB = "nextcloud";
      #     POSTGRES_USER = "luke";
      #     POSTGRES_PASSWORD = "luke";
      #     # MYSQL_ROOT_PASSWORD = "root";
      #     # MYSQL_DATABASE = "nextcloud";
      #     # MYSQL_USER = "luke";
      #     # MYSQL_PASSWORD = "luke";
      #     TZ = vars.timeZone;
      #   };
      #   extraOptions = [
      #     "--network=nextcloud-net"
      #   ];
      # };
      # nextcloud_db = {
      #   image = "mariadb:10.11";
      #   autoStart = true;
      #   volumes = [
      #     "${nextcloudDbDir}:/var/lib/mysql"
      #   ];
      #   # ports = [
      #   #   "3306:3306"
      #   # ];
      #   cmd = [
      #     # MariaDB fix
      #     "--innodb-read-only-compressed=OFF"
      #     "--transaction-isolation=READ-COMMITTED"
      #     "--log-bin=binlog"
      #     "--binlog-format=ROW"
      #   ];
      #   environment = {
      #     MYSQL_ROOT_PASSWORD = "root";
      #     MYSQL_DATABASE = "nextcloud";
      #     MYSQL_USER = "luke";
      #     MYSQL_PASSWORD = "luke";
      #     TZ = vars.timeZone;
      #   };
      #   extraOptions = [
      #     "--network=nextcloud-net"
      #   ];
      # };
    };
  };

  # Firewall rules for Nextcloud
  networking.firewall.allowedTCPPorts = [ 8080 ]; # Port for Nextcloud
}