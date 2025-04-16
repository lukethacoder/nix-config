{ config, vars, ... }:
let
  directories = [
    "${vars.serviceConfigRoot}/qbittorrent"
    "${vars.serviceConfigRoot}/gluetun"
    # "${vars.serviceConfigRoot}/sabnzbd"
    # "${vars.serviceConfigRoot}/radarr"
    # "${vars.serviceConfigRoot}/prowlarr"
    # "${vars.serviceConfigRoot}/recyclarr"
    "${vars.serviceConfigRoot}/Downloads.tmp"
    "${vars.serviceConfigRoot}/Downloads"
  ];
in
{
  systemd.tmpfiles.rules = map (x: "d ${x} 0775 share share - -") directories;

  virtualisation.oci-containers = {
    containers = {
      qbittorrent = {
        image = "linuxserver/qbittorrent:latest";
        autoStart = true;
        dependsOn = [
          "gluetun"
        ];
        extraOptions = [
          "--pull=newer"
          "--network=container:gluetun"
          "-l=homepage.group=Arr"
          "-l=homepage.name=qbittorrent"
          "-l=homepage.icon=qbittorrent.svg"
          "-l=homepage.href=https://torrent.${vars.domainName}"
          "-l=homepage.description=Torrent client"
          "-l=homepage.widget.type=qbittorrent"
          "-l=homepage.widget.username={{HOMEPAGE_FILE_QBITTORRENT_USERNAME}}"
          "-l=homepage.widget.password={{HOMEPAGE_FILE_QBITTORRENT_PASSWORD}}"
          "-l=homepage.widget.enableLeechProgress=true"
          "-l=homepage.widget.url=http://gluetun:8112"
        ];
        volumes = [
          "${vars.serviceConfigRoot}/Downloads:/data/completed"
          "${vars.serviceConfigRoot}/Downloads.tmp:/downloads"
          "${vars.serviceConfigRoot}/qbittorrent:/config"
        ];
        environment = {
          TZ = vars.timeZone;
          PUID = "994";
          GUID = "993";
          WEBUI_PORT = "8112";
          TORRENTING_PORT = "6881";
        };
      };
      gluetun = {
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
          # I know, we shouldn't be using readFile here, but gluetun doesn't like parsing the paths
          # WIREGUARD_ENDPOINT_IP = config.sops.secrets."wireguard/endpoint_ip".path;
          # WIREGUARD_ENDPOINT_PORT = config.sops.secrets."wireguard/endpoint_port".path;
          # WIREGUARD_PUBLIC_KEY = config.sops.secrets."wireguard/public_key".path;
          # WIREGUARD_PRIVATE_KEY = config.sops.secrets."wireguard/private_key".path;
          # WIREGUARD_ADDRESSES = builtins.readFile config.sops.secrets."wireguard/addresses".path;
          # WIREGUARD_ADDRESSES = "10.13.91.97/24";
        };
      };
    };
  };

  system.activationScripts.giveUserAccessToQbittorrentDir = 
    let
      user = config.users.users.luke.name;
      group = config.users.users.luke.group;
    in
      ''
        chown -R ${user}:${group} ${vars.serviceConfigRoot}/qbittorrent
        chown -R ${user}:${group} ${vars.serviceConfigRoot}/Downloads
        chown -R ${user}:${group} ${vars.serviceConfigRoot}/Downloads.tmp
      '';
}
