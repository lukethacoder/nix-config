{ config, vars, pkgs, ... }:
let directories = [
  "${vars.serviceConfigRoot}/obsidian"
];
in {
  systemd.tmpfiles.rules = map (x: "d ${x} 0775 share share - -") directories;

  virtualisation.oci-containers = {
    containers = {
      obsidian = {
        image = "lscr.io/linuxserver/obsidian";
        autoStart = true;
        ports = [
          "3030:3000"
          "3031:3001"
        ];
        extraOptions = [
          "--device=/dev/dri:/dev/dri"
          "--shm-size=1gb"
          "-l=traefik.enable=true"
          "-l=traefik.http.routers.obsidian.rule=Host(`obsidian.${builtins.readFile config.sops.secrets.domain_name.path}`)"
          "-l=traefik.http.services.obsidian.loadbalancer.server.port=8096"
          "-l=homepage.group=Media"
          "-l=homepage.name=Obsidian"
          "-l=homepage.icon=obsidian.png"
          "-l=homepage.href=https://obsidian.${builtins.readFile config.sops.secrets.domain_name.path}"
          "-l=homepage.description=Notes"
        ];
        volumes = [
          "${vars.serviceConfigRoot}/obsidian:/config"
        ];
        environment = {
          TZ = config.sops.secrets.time_zone.path;
          PUID = "994";
          GUID = "993";
        };
      };
    };
  };
}