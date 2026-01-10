{ config, vars, pkgs, ... }:
let
  configPath = "${vars.serviceConfigRoot}/prometheus";
  configFilePath = "${configPath}/prometheus.yml";
  directories = [ configPath ];

  # Copyparty Configuration
  prometheusYml = pkgs.writeText "prometheus.yml" ''
    global:
      scrape_interval: 10s

    # Configurations
    scrape_configs:
      - job_name: "navidrome"
        scheme: "https"
        static_configs:
          - targets: ["navidrome.${vars.domainName}"]
  '';
in
{
  systemd.tmpfiles.rules = map (x: "d ${x} 0777 472 0 - -") directories;

  # Create a prometheus.yml file
  systemd.services."podman-prometheus" = {
    preStart = ''
      mkdir -p ${configPath}
      cp ${prometheusYml} ${configFilePath}
      chown share:share ${configFilePath}
      chmod 0644 ${configFilePath}
    '';
  };

  virtualisation.oci-containers = {
    containers = {
      prometheus = {
        image = "prom/prometheus";
        autoStart = true;
        extraOptions = [
          "--pull=newer"
          "-l=traefik.enable=true"
          "-l=traefik.http.routers.prometheus.rule=Host(`prometheus.${vars.domainName}`)"
          "-l=homepage.group=Services"
          "-l=homepage.name=Prometheus"
          "-l=homepage.icon=prometheus"
          "-l=homepage.href=https://prometheus.${vars.domainName}"
          "-l=homepage.description=Monitoring and Alerts"
          "-l=homepage.widget.type=prometheus"
          "-l=homepage.widget.url=https://prometheus.${vars.domainName}"
        ];
        cmd = [
          "--config.file=/prometheus/prometheus.yml"
        ];
        volumes = [
          "${configPath}:/prometheus"
        ];
        ports = [ "9090:9090" ];
      };
    };
  };
}