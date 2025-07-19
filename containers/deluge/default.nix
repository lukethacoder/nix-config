{ config, vars, ... }:
let

  delugeUser = "deluge";
  delugeGroup = "deluge";
  delugeUserUID = "404";
  delugeGroupGID = "405";

  directories = [
    "${vars.serviceConfigRoot}/deluge/config"
    "${vars.serviceConfigRoot}/gluetun"
    # "${vars.serviceConfigRoot}/sabnzbd"
    # "${vars.serviceConfigRoot}/radarr"
    # "${vars.serviceConfigRoot}/prowlarr"
    # "${vars.serviceConfigRoot}/recyclarr"
    "${vars.mainArray}/Media/Downloads"
    "${vars.serviceConfigRoot}/Downloads.tmp"
    "${vars.serviceConfigRoot}/Downloads"
  ];
in
{
  users.users.${delugeUser} = {
    uid = builtins.fromJSON delugeUserUID;
    group = delugeGroup;
    isSystemUser = true;
  };
  users.groups.${delugeGroup} = {
    gid = builtins.fromJSON delugeGroupGID;
  };

  users.users.luke.extraGroups = [ delugeGroup ];

  systemd.tmpfiles.rules = map (x: "d ${x} 0775 ${delugeUser} ${delugeGroup} - -") directories;


  # Copy local deluge.conf to act as the core.conf for the container
  # home.file = {
  #   "${specialArgs.vars.serviceConfigRoot}/deluge/deluge.conf".source = ./deluge.conf;
  # };
  
  systemd.services.deluge-copy-config = {
    description = "Copy deluge.conf before container is started";
    before = [
      "podman-deluge.service"
      "podman-gluetun.service"
    ];
    wantedBy = [
      "podman-deluge.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      # Allow the service to be restarted without error
      RemainAfterExit = true;
      User = delugeUser;
      Group = delugeGroup;
    };
    script = ''
      mkdir -p ${vars.serviceConfigRoot}/deluge/config
      if cp ${builtins.path { path = ./deluge.conf; }} ${vars.serviceConfigRoot}/deluge/config/deluge.conf; then
        echo "Config file copied successfully."
        chown ${delugeUser}:${delugeGroup} ${vars.serviceConfigRoot}/deluge/config/deluge.conf
        chown 644 ${vars.serviceConfigRoot}/deluge/config/deluge.conf
      else
        echo "Error copying deluge config file."
        exit 1
      fi
    '';
  };

  virtualisation.oci-containers = {
    containers = {
      deluge = {
        image = "linuxserver/deluge:2.2.0";
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
          "-l=homepage.href=https://deluge.${vars.domainName}"
          "-l=homepage.description=Torrent client"
          "-l=homepage.widget.type=deluge"
          "-l=homepage.widget.password=deluge"
          "-l=homepage.widget.url=http://gluetun:8112"
        ];
        volumes = [
          "${vars.mainArray}/Media/Downloads:/data/completed"
          "${vars.serviceConfigRoot}/Downloads.tmp:/data/incomplete"
          "${vars.serviceConfigRoot}/deluge/config:/config"
          "${vars.serviceConfigRoot}/deluge/config/deluge.conf:/config/core.conf"
        ];
        environment = {
          TZ = vars.timeZone;
          PUID = delugeUserUID;
          GUID = delugeGroupGID;
          DELUGE_LOGLEVEL = "info";
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
    };
  };

  systemd.services.fix-deluge-permissions = {
    description = "Fix deluge directory permissions";
    after = [ "local-fs.target" ];
    before = [
      "podman-deluge.service"
      "podman-gluetun.service"
    ];
    wantedBy = [
      "multi-user.target"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Ensure directories exist and have correct ownership
      ${builtins.concatStringsSep "\n" (map (dir: ''
        mkdir -p "${dir}"
        chown -R ${delugeUser}:${delugeGroup} "${dir}"
        chmod -R 775 "${dir}"
      '') directories)}
    '';
  };

  # system.activationScripts.fix-deluge-permissions = 
  #   let
  #     user = config.users.users.luke.name;
  #     group = config.users.users.luke.group;
  #     # userSystem = config.users.users.deluge.name;
  #     # groupSystem = config.users.users.deluge.group;
  #   in
  #     ''
  #       chown -R ${user}:${group} ${vars.serviceConfigRoot}/deluge/config
  #       chown -R ${user}:${group} ${vars.mainArray}/Media/Downloads
  #       chown -R ${user}:${group} ${vars.serviceConfigRoot}/Downloads.tmp
  #     '';
      # chown -R ${userSystem}:${groupSystem} ${vars.serviceConfigRoot}/deluge/config
      # chown -R ${userSystem}:${groupSystem} ${vars.serviceConfigRoot}/Downloads
      # chown -R ${userSystem}:${groupSystem} ${vars.serviceConfigRoot}/Downloads.tmp

}
