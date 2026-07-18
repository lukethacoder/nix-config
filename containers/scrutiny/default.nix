{ vars, ... }:
{
  homelab.services.scrutiny = {
    image = "ghcr.io/analogj/scrutiny:master-omnibus";
    subdomain = "scrutiny";
    port = 8080;
    publishPorts = [
      "8084:8080" # Web UI
      "8086:8086" # InfluxDB admin
    ];
    dirs = [
      "${vars.serviceConfigRoot}/scrutiny"
      "${vars.serviceConfigRoot}/scrutiny/config"
      "${vars.serviceConfigRoot}/scrutiny/influxdb"
    ];
    volumes = [
      "/run/udev:/run/udev:ro"
      "${vars.serviceConfigRoot}/scrutiny/config:/opt/scrutiny/config"
      "${vars.serviceConfigRoot}/scrutiny/influxdb:/opt/scrutiny/influxdb"
    ];
    # image doesn't consume PUID/PGID
    user = null;
    extraPodmanArgs = [
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

      "-l=traefik.http.routers.scrutiny.service=scrutiny"
    ];
    homepage = {
      group = "Services";
      name = "Scrutiny";
      icon = "scrutiny.svg";
      description = "S.M.A.R.T. Monitoring";
      widget = {
        type = "scrutiny";
        url = "https://scrutiny.${vars.domainName}";
      };
    };
  };
}
