{ vars, ... }:
{
  # grafana runs as its own uid, not the share identity
  systemd.tmpfiles.rules = [
    "d ${vars.serviceConfigRoot}/grafana 0775 472 0 - -"
  ];

  homelab.services.grafana = {
    image = "grafana/grafana";
    subdomain = "grafana";
    # port omitted: traefik auto-detects the exposed port
    publishPorts = [ "3232:3000" ];
    volumes = [
      "${vars.serviceConfigRoot}/grafana:/var/lib/grafana"
    ];
    # image doesn't consume PUID/PGID
    user = null;
    homepage = {
      group = "Services";
      name = "Grafana";
      icon = "grafana";
      description = "Dashboards";
    };
  };
}
