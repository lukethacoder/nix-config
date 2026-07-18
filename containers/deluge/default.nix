{ config, lib, vars, ... }:
{
  # No traefik labels here: deluge shares gluetun's network namespace, so the
  # `deluge` router labels live on the gluetun sidecar below.
  homelab.services.deluge = {
    image = "linuxserver/deluge:2.2.0";
    dirs = [
      "${vars.serviceConfigRoot}/deluge/config"
      "${vars.serviceConfigRoot}/gluetun"
      "${vars.mainArray}/Media/Downloads"
      "${vars.serviceConfigRoot}/Downloads.tmp"
      "${vars.serviceConfigRoot}/Downloads"
    ];
    volumes = [
      "${vars.mainArray}/Media/Downloads:/data/completed"
      "${vars.serviceConfigRoot}/Downloads.tmp:/data/incomplete"
      "${vars.serviceConfigRoot}/deluge/config:/config"
      "${vars.serviceConfigRoot}/deluge/config/deluge.conf:/config/core.conf"
    ];
    env = {
      DELUGE_LOGLEVEL = "info";
    };
    extraPodmanArgs = [
      "--network=container:gluetun"
    ];
    extraContainerConfig = {
      dependsOn = [
        "gluetun"
      ];
    };
    homepage = {
      group = "Arr";
      name = "Deluge";
      icon = "deluge.svg";
      href = "https://deluge.${vars.domainName}";
      description = "Torrent client";
      widget = {
        type = "deluge";
        password = "deluge";
        url = "http://gluetun:8112";
      };
    };
  };

  # Sidecar: VPN gateway. Carries deluge's traefik router because deluge has
  # no network of its own. Gated on deluge's enable flag so the qbittorrent
  # stack (which defines its own gluetun) can be swapped in.
  virtualisation.oci-containers.containers.gluetun = lib.mkIf config.homelab.services.deluge.enable {
    image = "qmcgaw/gluetun:latest";
    autoStart = true;
    extraOptions = [
      "--pull=newer"
      "--cap-add=NET_ADMIN"
      "--device=/dev/net/tun:/dev/net/tun"
      "-l=traefik.enable=true"
      "-l=traefik.http.routers.deluge.rule=Host(`deluge.${vars.domainName}`)"
      "-l=traefik.http.routers.deluge.service=deluge"
      "-l=traefik.http.services.deluge.loadbalancer.server.port=8112"
      "-l=homepage.group=Arr"
      "-l=homepage.name=Gluetun"
      "-l=homepage.icon=gluetun.svg"
      "-l=homepage.href=https://deluge.${vars.domainName}"
      "-l=homepage.description=VPN killswitch"
      "-l=homepage.widget.type=gluetun"
      "-l=homepage.widget.url=http://gluetun:8000"
    ];
    ports = [
      "127.0.0.1:8083:8000"
    ];
    volumes = [
      "${vars.serviceConfigRoot}/gluetun:/gluetun"
    ];
    environmentFiles = [
      config.sops.templates."wireguard-env".path
    ];
    environment = {
      TZ = vars.timeZone;
      VPN_TYPE = "wireguard";
      VPN_SERVICE_PROVIDER = "custom";
    };
  };
}
