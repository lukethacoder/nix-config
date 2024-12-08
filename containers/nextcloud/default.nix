{ config, pkgs, ... }:

let
  nextcloudDataDir = "${vars.serviceConfigRoot}/nextcloud-data";
  nextcloudDbDir = "${vars.serviceConfigRoot}/nextcloud-db";
in
{
  # Ensure necessary directories exist
  systemd.tmpfiles.rules = [
    "d ${nextcloudDataDir} 0755 nextcloud nextcloud -"
    "d ${nextcloudDbDir} 0755 nextcloud nextcloud -"
  ];

  # User and group for Nextcloud
  users.users.nextcloud = {
    isSystemUser = true;
    home = nextcloudDataDir;
  };

  users.groups.nextcloud = {};

  # Enable Docker service
  services.docker.enable = true;

  # Nextcloud container
  services.docker.containers.nextcloud = {
    image = "nextcloud:latest"; # Change tag if specific version is required
    volumes = [
      "${nextcloudDataDir}:/var/www/html/data"
    ];
    environment = {
      MYSQL_HOST = "nextcloud-db";    # Database container name
      MYSQL_DATABASE = "nextcloud";
      MYSQL_USER = "nextcloud";
      MYSQL_PASSWORD = "supersecretpassword"; # Replace with a secure password
    };
    ports = [
      "8080:80" # Map host port 8080 to container port 80
    ];
    restartPolicy = "always";
    networks = ["nextcloud-network"];
  };

  # MariaDB container for Nextcloud
  services.docker.containers."nextcloud-db" = {
    image = "mariadb:10.11"; # Adjust version as needed
    volumes = [
      "${nextcloudDbDir}:/var/lib/mysql"
    ];
    environment = {
      MYSQL_ROOT_PASSWORD = "rootpassword"; # Replace with a secure password
      MYSQL_DATABASE = "nextcloud";
      MYSQL_USER = "nextcloud";
      MYSQL_PASSWORD = "supersecretpassword"; # Match the Nextcloud container password
    };
    restartPolicy = "always";
    networks = ["nextcloud-network"];
  };

  # Custom network for Nextcloud containers
  services.docker.networks.nextcloud-network = {
    enableBridge = true;
  };

  # Firewall rules for Nextcloud
  networking.firewall.allowedTCPPorts = [ 8080 ]; # Port for Nextcloud
}