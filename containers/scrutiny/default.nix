{ config, pkgs, ... }:
{
  virtualisation.oci-containers.containers."scrutiny" = {
    autoStart = true;
    image = "ghcr.io/analogj/scrutiny:master-omnibus";

    ports = [
      "8080:8080" # Web UI
      "8086:8086" # InfluxDB admin
    ];

    volumes = [
      "/run/udev:/run/udev:ro"
      "/opt/scrutiny/config:/opt/scrutiny/config"
      "/opt/scrutiny/influxdb:/opt/scrutiny/influxdb"
    ];

    # SYS_RAWIO is required for SMART data access
    # SYS_ADMIN is required for NVMe drives
    extraOptions = [
      "--cap-add=SYS_RAWIO"
      "--cap-add=SYS_ADMIN"

      # SSD Boot Drive
      "--device=/dev/disk/by-uuid/89508460-a7c2-4869-9bf9-1cdbd22efe51"

      # HDDs
      "--device=/dev/disk/by-partlabel/disk-data1-data"
      "--device=/dev/disk/by-partlabel/disk-data2-data"
      "--device=/dev/disk/by-partlabel/disk-data3-data"
      "--device=/dev/disk/by-partlabel/disk-parity1-parity"

      "-l=homepage.group=Services"
      "-l=homepage.name=Scrutiny"
      "-l=homepage.icon=scrutiny.svg"
      "-l=homepage.href=https://scrutiny.${vars.domainName}"
      "-l=homepage.description=S.M.A.R.T. Monitoring"
      "-l=homepage.widget.type=scrutiny"
      "-l=homepage.widget.url=https://scrutiny.${vars.domainName}"
    ];
  };
}
