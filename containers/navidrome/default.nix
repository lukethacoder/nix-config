{ config, vars, pkgs, ... }:
let directories = [
  "${vars.serviceConfigRoot}/gonic"
  "${vars.mainArray}/Media/Music"
];
in {
  systemd.tmpfiles.rules = map (x: "d ${x} 0775 share share - -") directories;

  system.userActivationScripts.navidrome-data.text = ''
    mkdir -p ${vars.serviceConfigRoot}/navidrome \
      ${vars.mainArray}/Media/Music/Music
  '';

  virtualisation.oci-containers = {
    containers = {
      navidrome = {
        image = "deluan/navidrome:latest";
        autoStart = true;
        ports = [ "4533:4533" ];
        volumes = [
          "${vars.serviceConfigRoot}/navidrome/data:/data"
          "${vars.mainArray}/Media/Music/Music:/music:ro"
        ];
        environment = {
          TZ = config.sops.secrets.time_zone.path;
          ND_SCANSCHEDULE = "1h";
          ND_LOGLEVEL = "info";
          ND_SESSIONTIMEOUT = "24h";
          # ND_BASEURL = "";
          # PUID = "994";
          # UMASK = "002";
          # GUID = "993";
        };
        extraOptions = [
          # "--device=/dev/snd:/dev/snd"
          # "-multi-value-genre=multi"
          # "-multi-value-artist=multi"
          # "-multi-value-album-artist=multi"
          "-l=traefik.enable=true"
          "-l=traefik.http.routers.navidrome.rule=Host(`navidrome.${builtins.readFile config.sops.secrets.domain_name.path}`)"
          "-l=traefik.http.services.navidrome.loadbalancer.server.port=4533"
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
      };
    };
  };
}