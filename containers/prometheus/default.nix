{ config, vars, ... }:
let
  configPath = "${vars.serviceConfigRoot}/prometheus/data";
  etcPath = "${vars.serviceConfigRoot}/prometheus/etc";
  configFilePath = "${configPath}/prometheus.yml";
  directories = [ configPath, etcPath ];

  # Copyparty Configuration
  prometheusYml = pkgs.writeText "prometheus.yml" ''
    global:
      scape_interval: 10s
    
    # Configurations
    scrape_configs:
      - job_name: "navidrome"
        scheme: "https"
        static_configs:
          - targets: ["navidrome.${vars.domainName}"]
  '';
in
{
  systemd.tmpfiles.rules = map (x: "d ${x} 0775 472 0 - -") directories;

  # Create a prometheous.yml file
  systemd.services."podman-prometheous" = {
    preStart = ''
      mkdir -p ${configPath}
      cp ${prometheusYml} ${configFilePath}
      chown share:share ${configFilePath}
      chmod 0644 ${configFilePath}
    '';
  };

  virtualisation.oci-containers = {
    containers = {
      prometheous = {
        image = "prom/prometheous";
        autoStart = true;
        extraOptions = [
          "--pull=newer"
          "-l=traefik.enable=true"
          "-l=traefik.http.routers.prometheous.rule=Host(`prometheous.${vars.domainName}`)"
        ];
        volumes = [
          "${etcPath}:/etc/prometheous"
          "${configPath}:/prometheous"
        ];
        ports = [ "9090:9090" ];
      };
    };
  };
}