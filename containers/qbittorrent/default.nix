{ config, vars, ... }:
{
  users = {
    groups.qbittorrent = {
      gid = 1100;
    };
    users.qbittorrent = {
      uid = 1100;
      isSystemUser = true;
      group = "qbittorrent";
    };
  };

  # No traefik labels here: qbittorrent shares gluetun's network namespace, so
  # the `qbittorrent` router labels live on the gluetun sidecar below.
  homelab.services.qbittorrent = {
    image = "linuxserver/qbittorrent:5.1.0";
    dirs = [
      "${vars.serviceConfigRoot}/qbittorrent"
      "${vars.serviceConfigRoot}/gluetun"
      "${vars.serviceConfigRoot}/Downloads.tmp"
      "${vars.serviceConfigRoot}/Downloads"
    ];
    volumes = [
      "${vars.serviceConfigRoot}/Downloads:/data/completed"
      "${vars.serviceConfigRoot}/Downloads.tmp:/downloads"
      "${vars.serviceConfigRoot}/qbittorrent:/config"
    ];
    user = {
      uid = config.users.users.qbittorrent.uid;
      gid = config.users.groups.qbittorrent.gid;
    };
    env = {
      WEBUI_PORT = "8112";
      TORRENTING_PORT = "6881";
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
      name = "qbittorrent";
      icon = "qbittorrent.svg";
      href = "https://torrent.${vars.domainName}";
      description = "Torrent client";
      widget = {
        type = "qbittorrent";
        username = "{{HOMEPAGE_FILE_QBITTORRENT_USERNAME}}";
        password = "{{HOMEPAGE_FILE_QBITTORRENT_PASSWORD}}";
        enableLeechProgress = "true";
        url = "http://gluetun:8112";
      };
    };
  };

  # Sidecar: VPN gateway. Carries qbittorrent's traefik router because
  # qbittorrent has no network of its own.
  virtualisation.oci-containers.containers.gluetun = {
    image = "qmcgaw/gluetun:latest";
    autoStart = true;
    extraOptions = [
      "--pull=newer"
      "--cap-add=NET_ADMIN"
      "--device=/dev/net/tun:/dev/net/tun"
      "-l=traefik.enable=true"
      "-l=traefik.http.routers.qbittorrent.rule=Host(`torrent.${vars.domainName}`)"
      "-l=traefik.http.routers.qbittorrent.service=qbittorrent"
      "-l=traefik.http.services.qbittorrent.loadbalancer.server.port=8112"
      "-l=homepage.group=Arr"
      "-l=homepage.name=Gluetun"
      "-l=homepage.icon=gluetun.svg"
      "-l=homepage.href=https://torrent.${vars.domainName}"
      "-l=homepage.description=VPN killswitch"
      "-l=homepage.widget.type=gluetun"
      "-l=homepage.widget.url=http://gluetun:8000"
    ];
    ports = [
      "127.0.0.1:8112:8112"
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

  system.activationScripts.giveUserAccessToQbittorrentDir =
    let
      user = config.users.users.luke.name;
      group = config.users.users.luke.group;
      userSystem = config.users.users.qbittorrent.name;
      groupSystem = config.users.users.qbittorrent.group;
    in
      ''
        chown -R ${user}:${group} ${vars.serviceConfigRoot}/qbittorrent
        chown -R ${user}:${group} ${vars.serviceConfigRoot}/Downloads
        chown -R ${user}:${group} ${vars.serviceConfigRoot}/Downloads.tmp

        chown -R ${userSystem}:${groupSystem} ${vars.serviceConfigRoot}/qbittorrent
        chown -R ${userSystem}:${groupSystem} ${vars.serviceConfigRoot}/Downloads
        chown -R ${userSystem}:${groupSystem} ${vars.serviceConfigRoot}/Downloads.tmp
      '';
}
