{ config, lib, pkgs, vars, ... }:
{
  system.activationScripts.adguard_folder_config = ''
    mkdir -p "${vars.serviceConfigRoot}/adguard/work" \
      "${vars.serviceConfigRoot}/adguard/conf"
  '';

  networking = {
    firewall = {
      allowedTCPPorts = [ 53 433 ];
      allowedUDPPorts = [ 53 433 ];
    };
    nameservers = [
      "10.88.0.92"
      "1.1.1.1"
      "8.8.8.8"
    ];
  };

  virtualisation.oci-containers = {
    containers = {
      adguardhome = {
        image = "adguard/adguardhome";
        autoStart = true;

        extraOptions = [
          # "--network=host"
          # "--network-alias=adguardhome"
          "-l=traefik.enable=true"
          "-l=traefik.http.routers.adguard.rule=Host(`adguard.${builtins.readFile config.sops.secrets.domain_name.path}`)"
          "-l=traefik.http.services.adguard.loadbalancer.server.port=83"

          "-l=homepage.group=Services"
          "-l=homepage.name=AdGuard"
          "-l=homepage.icon=adguard-home.svg"
          "-l=homepage.href=https://adguard.${builtins.readFile config.sops.secrets.domain_name.path}"
          "-l=homepage.description=DNS and Adblocking"
          "-l=homepage.widget.url=http://192.168.0.30:83"
          "-l=homepage.widget.type=adguard"
          "-l=homepage.widget.username={{ADGUARD_USERNAME}}"
          "-l=homepage.widget.password={{ADGUARD_PASSWORD}}"
          "-l=homepage.widget.fields=['queries', 'blocked', 'filtered', 'latency']"
        ];
        ports = [
          "53:53"
          "83:80"
          "3003:3000"
        ];
        environment = {
          ADGUARD_USERNAME = config.sops.secrets."adguard/username".path;
          ADGUARD_PASSWORD = config.sops.secrets."adguard/password".path;
        };
        volumes = [
          "${vars.serviceConfigRoot}/adguard/work:/opt/adguardhome/work:rw"
          "${vars.serviceConfigRoot}/adguard/conf:/opt/adguardhome/conf:rw"
        ];
      };
    };
  };

  # systemd.services."docker-adguardhome" = {
  #   serviceConfig = {
  #     Restart = lib.mkOverride 500 "always";
  #     RestartMaxDelaySec = lib.mkOverride 500 "1m";
  #     RestartSec = lib.mkOverride 500 "100ms";
  #     RestartSteps = lib.mkOverride 500 9;
  #   };
  #   after = [
  #     "docker-network-adguard-home_default.service"
  #   ];
  #   requires = [
  #     "docker-network-adguard-home_default.service"
  #   ];
  #   partOf = [
  #     "docker-compose-adguard-home-root.target"
  #   ];
  #   wantedBy = [
  #     "docker-compose-adguard-home-root.target"
  #   ];
  # };

  # # Networks
  # systemd.services."docker-network-adguard-home_default" = {
  #   path = [pkgs.docker];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #     ExecStop = "${pkgs.docker}/bin/docker network rm -f adguard-home_default";
  #   };
  #   script = ''
  #     docker network inspect adguard-home_default || docker network create adguard-home_default
  #   '';
  #   partOf = ["docker-compose-adguard-home-root.target"];
  #   wantedBy = ["docker-compose-adguard-home-root.target"];
  # };

  # # Root service
  # # When started, this will automatically create all resources and start
  # # the containers. When stopped, this will teardown all resources.
  # systemd.targets."docker-compose-adguard-home-root" = {
  #   unitConfig = {
  #   };
  #   wantedBy = ["multi-user.target"];
  # };
}