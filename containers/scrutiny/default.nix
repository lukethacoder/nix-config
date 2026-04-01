{ config, vars, pkgs, ... }:
let
  directories = [
    "${vars.serviceConfigRoot}/scrutiny"
  ];
in {
  systemd.tmpfiles.rules = map (x: "d ${x} 0775 share share - -") directories;

  system.userActivationScripts.scrutiny-data.text = ''
    mkdir -p ${vars.serviceConfigRoot}/scrutiny/config \
      ${vars.serviceConfigRoot}/scrutiny/influxdb
  '';

  virtualisation.oci-containers = {
    containers = {
      scrutiny = {
        image = "ghcr.io/analogj/scrutiny:master-omnibus";
        autoStart = true;
        ports = [
          "8084:8080" # Web UI
          "8086:8086" # InfluxDB admin
        ];
        volumes = [
          "/run/udev:/run/udev:ro"
          "${vars.serviceConfigRoot}/scrutiny/config:/opt/scrutiny/config"
          "${vars.serviceConfigRoot}/scrutiny/influxdb:/opt/scrutiny/influxdb"
        ];
        extraOptions = [
          # SYS_RAWIO is required for SMART data access
          "--cap-add=SYS_RAWIO"
          # SYS_ADMIN is required for NVMe drives
          "--cap-add=SYS_ADMIN"

          # SSD Boot Drive
          "--device=/dev/nvme0n1"

          # HDDs
          "--device=/dev/disk/by-id/ata-ST16000NM001G-2KK103_ZL20PRJR"
          "--device=/dev/disk/by-id/ata-ST16000NM001G-2KK103_ZL2A58E2"
          "--device=/dev/disk/by-id/ata-ST16000NM001G-2KK103_ZL2F9ZEP"
          "--device=/dev/disk/by-id/ata-ST16000NM001G-2KK103_ZL2GVRCT"

          "-l=traefik.enable=true"
          "-l=traefik.http.routers.scrutiny.rule=Host(`scrutiny.${vars.domainName}`)"
          "-l=traefik.http.routers.scrutiny.service=scrutiny"
          "-l=traefik.http.services.scrutiny.loadbalancer.server.port=8080"

          "-l=homepage.group=Services"
          "-l=homepage.name=Scrutiny"
          "-l=homepage.icon=scrutiny.svg"
          "-l=homepage.href=https://scrutiny.${vars.domainName}"
          "-l=homepage.description=S.M.A.R.T. Monitoring"
          "-l=homepage.widget.type=scrutiny"
          "-l=homepage.widget.url=https://scrutiny.${vars.domainName}"
        ];
      };
    };
  };
}
