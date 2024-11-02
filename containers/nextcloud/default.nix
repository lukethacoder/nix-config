{ config, pkgs, ... }:
{
  # Network linker
  system.activationScripts.NextcloudNetwork =
    let
      backend = config.virtualisation.oci-containers.backend;
      backendBin = "${pkgs.${backend}}/bin/${backend}";
    in
    ''
      ${backendBin} network create nextcloud-net --subnet 172.20.0.0/16 || true
    '';

  virtualisation.oci-containers.containers = {
    # Database
    "nextcloud-db" = {
      autoStart = true;
      image = "mariadb:10.5";
      cmd = [
        "--transaction-isolation=READ-COMMITTED"
        "--binlog-format=ROW"
      ];
      volumes = [
        "nextcloud-db:/var/lib/mysql"
      ];
      ports = [ "3306:3306" ];
      environment = {
        MYSQL_ROOT_PASSWORD = "nextcloud";
        MYSQL_PASSWORD = "nextcloud";
        MYSQL_DATABASE = "nextcloud";
        MYSQL_USER = "nextcloud";
      };
      extraOptions = [
        "--network=nextcloud-net"
      ];
    };

    # NextCloud
    "nextcloud" = {
      image = "nextcloud";
      ports = [ "8080:80" ];
      dependsOn = [
        "nextcloud-db"
      ];
      environment = {
        MYSQL_PASSWORD = "nextcloud";
        MYSQL_DATABASE = "nextcloud";
        MYSQL_USER = "nextcloud";
        MYSQL_HOST = "nextcloud-db";
      };
      volumes = [
        "${vars.serviceConfigRoot}/nextcloud:/var/www/html"
      ];
      extraOptions = [
        "--network=nextcloud-net"
      ];
    };
  };
}