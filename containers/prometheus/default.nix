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
        ];
        volumes = [
          "${etcPath}:/etc/prometheus"
          "${configPath}:/prometheus"
        ];
        ports = [ "9090:9090" ];
      };
    };
  };
}