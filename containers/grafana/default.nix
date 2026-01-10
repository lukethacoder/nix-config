{ config, vars, ... }:
let
  directories = [
    "${vars.serviceConfigRoot}/grafana"
  ];
in
{
  systemd.tmpfiles.rules = map (x: "d ${x} 0775 472 0 - -") directories;

  virtualisation.oci-containers = {
    containers = {
      grafana = {
        image = "grafana/grafana";
        autoStart = true;
        extraOptions = [
          "--pull=newer"
          "-l=traefik.enable=true"
          "-l=traefik.http.routers.grafana.rule=Host(`grafana.${vars.domainName}`)"
          "-l=homepage.group=Services"
          "-l=homepage.name=Grafana"
          "-l=homepage.icon=grafana"
          "-l=homepage.href=https://grafana.${vars.domainName}"
          "-l=homepage.description=Dashboards"
        ];
        volumes = [
          "${vars.serviceConfigRoot}/grafana:/var/lib/grafana"
        ];
        ports = [ "3232:3000" ];
      };
    };
  };
}