{ config, vars, ... }:
let
  directories = [
    "${vars.serviceConfigRoot}/deluge"
    "${vars.serviceConfigRoot}/sabnzbd"
    "${vars.serviceConfigRoot}/radarr"
    "${vars.serviceConfigRoot}/prowlarr"
    "${vars.serviceConfigRoot}/recyclarr"
    "${vars.mainArray}/Media/Downloads"
    "${vars.serviceConfigRoot}/Downloads.tmp"
  ];
in
{
  systemd.tmpfiles.rules = map (x: "d ${x} 0775 share share - -") directories;
  virtualisation.oci-containers = {
    containers = {
      deluge = {
        image = "linuxserver/deluge:latest";
        autoStart = true;
        dependsOn = [
          "gluetun"
        ];
        extraOptions = [
          "--pull=newer"
          "--network=container:gluetun"
          "-l=homepage.group=Arr"
          "-l=homepage.name=Deluge"
          "-l=homepage.icon=deluge.svg"
          "-l=homepage.href=https://deluge.${builtins.readFile config.sops.secrets.domain_name.path}"
          "-l=homepage.description=Torrent client"
          "-l=homepage.widget.type=deluge"
          "-l=homepage.widget.password=deluge"
          "-l=homepage.widget.url=http://gluetun:8112"
        ];
        volumes = [
          "${vars.mainArray}/Media/Downloads:/data/completed"
          "${vars.serviceConfigRoot}/Downloads.tmp:/data/incomplete"
          "${vars.serviceConfigRoot}/deluge:/config"
        ];
        environment = {
          TZ = vars.timeZone;
          PUID = "994";
          GUID = "993";
        };
      };
      gluetun = {
        image = "qmcgaw/gluetun:latest";
        autoStart = true;
        extraOptions = [
          "--pull=newer"
          "--cap-add=NET_ADMIN"
          "-l=traefik.enable=true"
          "-l=traefik.http.routers.deluge.rule=Host(`deluge.${builtins.readFile config.sops.secrets.domain_name.path}`)"
          "-l=traefik.http.routers.deluge.service=deluge"
          "-l=traefik.http.services.deluge.loadbalancer.server.port=8112"
          "--device=/dev/net/tun:/dev/net/tun"
          "-l=homepage.group=Arr"
          "-l=homepage.name=Gluetun"
          "-l=homepage.icon=gluetun.svg"
          "-l=homepage.href=https://deluge.${builtins.readFile config.sops.secrets.domain_name.path}"
          "-l=homepage.description=VPN killswitch"
          "-l=homepage.widget.type=gluetun"
          "-l=homepage.widget.url=http://gluetun:8000"
        ];
        ports = [
          "127.0.0.1:8083:8000"
        ];
        environment = {
          VPN_TYPE = "wireguard";
          VPN_SERVICE_PROVIDER = "custom";
          WIREGUARD_ENDPOINT = config.sops.secrets."wireguard/enpoint_ip".path;
          WIREGUARD_ENDPOINT_PORT = config.sops.secrets."wireguard/enpoint_port".path;
          WIREGUARD_PUBLIC_KEY = config.sops.secrets."wireguard/public_key".path;
          WIREGUARD_PRIVATE_KEY = config.sops.secrets."wireguard/private_key".path;
          WIREGUARD_ADDRESSES = config.sops.secrets."wireguard/addresses".path;
        };
      };
    };
  };
}
