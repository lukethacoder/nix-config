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

  # Copy local deluge.conf to act as the core.conf for the container
  # home.file = {
  #   "${specialArgs.vars.serviceConfigRoot}/deluge/deluge.conf".source = ./deluge.conf;
  # };
  
  # systemd.services.deluge-copy-config = {
  #   description = "Copy deluge.conf before container is started";
  #   before = [
  #     "docker.service"
  #     "podman.service"
  #   ];
  #   wantedBy = [
  #     "docker.service"
  #     "podman.service"
  #   ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     # Allow the service to be restarted without error
  #     RemainAfterExit = true;
  #   };
  #   script = ''
  #     mkdir -p ${vars.serviceConfigRoot}/deluge/
  #     if cp ${builtins.path { path = ./deluge.conf; }} ${vars.serviceConfigRoot}/deluge/deluge.conf; then
  #       echo "Config file copied successfully."
  #     else
  #       echo "Error copying deluge config file."
  #       exit 1
  #     fi
  #   '';
  # };

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
          "-l=homepage.href=https://qbittorrent.${vars.domainName}"
          "-l=homepage.description=Torrent client"
          "-l=homepage.widget.type=qbittorrent"
          "-l=homepage.widget.username=qbittorrent"
          "-l=homepage.widget.password=qbittorrent"
          "-l=homepage.widget.enableLeechProgress=true"
          "-l=homepage.widget.url=http://gluetun:8112"
        ];
        volumes = [
          "${vars.serviceConfigRoot}/Downloads:/data/completed"
          "${vars.serviceConfigRoot}/Downloads.tmp:/downloads"
          "${vars.serviceConfigRoot}/qbittorrent:/config"
        ];
        # ports = [
        #   "8112:8112"
        # ];
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

  system.activationScripts.giveUserAccessToDelugeDir = 
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
