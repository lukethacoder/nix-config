{ config, vars, pkgs, ... }:
let directories = [
  "${vars.serviceConfigRoot}/homeassistant"
];
in {
  systemd.tmpfiles.rules = map (x: "d ${x} 0775 share share - -") directories;

  virtualisation.oci-containers = {
    containers = {
      homeassistant = {
        image = "homeassistant/home-assistant:stable";
        autoStart = true;
        ports = [
          "127.0.0.0:8123:8123"
        ];
        volumes = [
          "${vars.serviceConfigRoot}/homeassistant:/config"
          "/etc/localtime:/localtime:ro"
          "/run/dbus:/run/dbus:ro"
        ];
        environment = {
          TZ = vars.timeZone;
          PUID = "1000";
          PGID = "1000";
        };
        extraOptions = [
          "--pull=newer"
          "--network=host"
          "--privileged"
          "-l=traefik.enable=true"
          "-l=traefik.http.routers.homeassistant.rule=Host(`homeassistant.${vars.domainName}`)"
          "-l=traefik.http.services.homeassistant.loadbalancer.server.port=8123"
          "-l=homepage.group=Services"
          "-l=homepage.name=Home Assistant"
          "-l=homepage.icon=home-assistant.svg"
          "-l=homepage.href=https://homeassistant.${vars.domainName}"
          "-l=homepage.description=Home Assistant"
          "-l=homepage.widget.type=homeassistant"
          "-l=homepage.widget.url=https://homeassistant.${vars.domainName}"
        ];
      };
    };
  };
}