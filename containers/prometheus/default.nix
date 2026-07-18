{ vars, pkgs, ... }:
let
  configPath = "${vars.serviceConfigRoot}/prometheus";
  configFilePath = "${configPath}/prometheus.yml";

  # Prometheus Configuration
  prometheusYml = pkgs.writeText "prometheus.yml" ''
    global:
      scrape_interval: 10s

    # Configurations
    scrape_configs:
      - job_name: "navidrome"
        scheme: "https"
        static_configs:
          - targets: ["navidrome.${vars.domainName}"]
      - job_name: "immich-api"
        scheme: "http"
        static_configs:
          - targets: ["host.containers.internal:8081"]
      - job_name: "immich-microservices"
        scheme: "http"
        static_configs:
          - targets: ["host.containers.internal:8082"]
      - job_name: "jellyfin"
        scheme: "https"
        static_configs:
          - targets: ["jellyfin.${vars.domainName}"]
  '';
in
{
  # prometheus runs as its own uid, not the share identity
  systemd.tmpfiles.rules = [
    "d ${configPath} 0777 472 0 - -"
  ];

  # Create a prometheus.yml file
  systemd.services."podman-prometheus" = {
    preStart = ''
      mkdir -p ${configPath}
      cp ${prometheusYml} ${configFilePath}
      chown share:share ${configFilePath}
      chmod 0644 ${configFilePath}
    '';
  };

  homelab.services.prometheus = {
    image = "prom/prometheus";
    subdomain = "prometheus";
    # port omitted: traefik auto-detects the exposed port
    publishPorts = [ "9090:9090" ];
    volumes = [
      "${configPath}:/prometheus"
    ];
    # image doesn't consume PUID/PGID
    user = null;
    extraContainerConfig = {
      cmd = [
        "--config.file=/prometheus/prometheus.yml"
      ];
    };
    homepage = {
      group = "Services";
      name = "Prometheus";
      icon = "prometheus";
      description = "Monitoring and Alerts";
      widget = {
        type = "prometheus";
        url = "https://prometheus.${vars.domainName}";
      };
    };
  };
}
