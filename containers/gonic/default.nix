{ config, vars, pkgs, ... }:
let directories = [
  "${vars.serviceConfigRoot}/gonic"
  "${vars.mainArray}/Media/TV"
  "${vars.mainArray}/Media/Movies"
];
in {
  systemd.tmpfiles.rules = map (x: "d ${x} 0775 share share - -") directories;

  virtualisation.oci-containers = {
    containers = {
      jellyfin = {
        image = "lscr.io/sentriz/gonic";
        autoStart = true;
        ports = [ "4747:80" ];
        extraOptions = [
          "-multi-value-genre=multi"
          "-multi-value-artist=multi"
          "-multi-value-album-artist=multi"
          # "--device=/dev/dri:/dev/dri"
          "-l=traefik.enable=true"
          "-l=traefik.http.routers.gonic.rule=Host(`gonic.${builtins.readFile config.sops.secrets.domain_name.path}`)"
          "-l=traefik.http.services.gonic.loadbalancer.server.port=4747"
          # "-l=homepage.group=Media"
          # "-l=homepage.name=Gonic"
          # "-l=homepage.icon=gonic.svg"
          # "-l=homepage.href=https://gonic.${builtins.readFile config.sops.secrets.domain_name.path}"
          # "-l=homepage.description=Media player"
          # "-l=homepage.widget.type=gonic"
          # "-l=homepage.widget.key={{HOMEPAGE_FILE_JELLYFIN_KEY}}"
          # "-l=homepage.widget.url=http://gonic:4747"
          # "-l=homepage.widget.enableBlocks=true"
        ];
        volumes = [
          "${vars.serviceConfigRoot}/gonic/data:/data"
          "${vars.serviceConfigRoot}/gonic/playlists:/playlists"
          "${vars.serviceConfigRoot}/gonic/cache:/cache"
          "${vars.mainArray}/Media/Music/Music:/music:ro"
        ];
        environment = {
          TZ = config.sops.secrets.time_zone.path;
          # PUID = "994";
          # UMASK = "002";
          # GUID = "993";
        };
      };
    };
  };
}