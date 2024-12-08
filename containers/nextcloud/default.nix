{ config, pkgs, vars, ... }:

let
  nextcloudDataDir = "${vars.serviceConfigRoot}/nextcloud-data";
  nextcloudDbDir = "${vars.serviceConfigRoot}/nextcloud-db";
  nextcloudDbDirPostgres = "${vars.serviceConfigRoot}/nextcloud-db-postgres";
in
{
  system.activationScripts.nextcloudFolders = ''
    mkdir -p ${nextcloudDataDir}
    mkdir -p ${nextcloudDbDir}
    mkdir -p ${nextcloudDbDirPostgres}
  '';

  # Ensure necessary directories exist
  systemd.tmpfiles.rules = [
    "d ${nextcloudDataDir} 0755 nextcloud nextcloud -"
    "d ${nextcloudDbDir} 0755 nextcloud nextcloud -"
    "d ${nextcloudDbDirPostgres} 0755 nextcloud nextcloud -"
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
      nextcloud = {
        image = "nextcloud:latest";
        autoStart = true;
        dependsOn = [
          "nextcloud_db_02"
        ];
        volumes = [
          "${nextcloudDataDir}:/var/www/html/data"
        ];
        cmd = [
          "--restart=always"
          "--restart-delay=20s"
        ];
        environment = {
          # MariaDB
          # MYSQL_HOST = "192.168.8.202:3306";
          # MYSQL_HOST = "172.20.0.21";
          # MYSQL_HOST = "nextcloud_db";
          # MYSQL_DATABASE = "nextcloud";
          # MYSQL_USER = "luke";
          # MYSQL_PASSWORD = "luke";

          # Postgres
          POSTGRES_HOST = "nextcloud_db"; # may need a '_1' appended?
          POSTGRES_DB = "nextcloud";
          POSTGRES_USER = "luke";
          POSTGRES_PASSWORD = "luke";

          NEXTCLOUD_ADMIN_USER = "luke";
          NEXTCLOUD_ADMIN_PASSWORD = "luke";
          NEXTCLOUD_TRUSTED_DOMAINS = "localhost,192.168.8.202,nextcloud.lukethacoder.duckdns.org";
          TZ = vars.timeZone;
        };
        ports = [
          "8347:80"
        ];
        extraOptions = [
          "--network=nextcloud-net"
        ];
      };
      nextcloud_db_02 = {
        image = "postgres:17.2";
        autoStart = true;
        volumes = [
          "${nextcloudDbDirPostgres}:/var/lib/postgresql/data"
        ];
        ports = [
          "5433:5432"
        ];
        cmd = [
          "--restart=always"
          "--restart-delay=20s"
          # MariaDB fix
          # "--innodb-read-only-compressed=OFF"
          # "--transaction-isolation=READ-COMMITTED"
          # "--log-bin=binlog"
          # "--binlog-format=ROW"
        ];
        environment = {
          POSTGRES_DB = "nextcloud";
          POSTGRES_USER = "luke";
          POSTGRES_PASSWORD = "luke";
          # MYSQL_ROOT_PASSWORD = "root";
          # MYSQL_DATABASE = "nextcloud";
          # MYSQL_USER = "luke";
          # MYSQL_PASSWORD = "luke";
          TZ = vars.timeZone;
        };
        extraOptions = [
          "--network=nextcloud-net"
        ];
      };
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