{ config, vars, pkgs, ... }:
let directories = [
  "${vars.serviceConfigRoot}/gonic"
  "${vars.mainArray}/Media/Music"
];
in {
  systemd.tmpfiles.rules = map (x: "d ${x} 0775 share share - -") directories;

  system.userActivationScripts.gonic-data.text = ''
    mkdir -p ${vars.serviceConfigRoot}/gonic/data \
      ${vars.serviceConfigRoot}/gonic/playlists \
      ${vars.serviceConfigRoot}/gonic/cache \
      ${vars.mainArray}/Media/Music/Music
  '';

  virtualisation.oci-containers = {
    containers = {
      gonic = {
        image = "sentriz/gonic:latest";
        autoStart = true;
        ports = [ "4747:80" ];
        volumes = [
          "${vars.serviceConfigRoot}/gonic/data:/data"
          "${vars.serviceConfigRoot}/gonic/playlists:/playlists"
          "${vars.serviceConfigRoot}/gonic/cache:/cache"
          "${vars.mainArray}/Media/Music/Music:/music:ro"
        ];
        environment = {
          TZ = config.sops.secrets.time_zone.path;
          GONIC_MULTI_VALUE_GENRE = "multi";
          GONIC_MULTI_VALUE_ARTIST = "multi";
          GONIC_MULTI_VALUE_ALBUM_ARTIST = "multi";
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
          "-l=traefik.http.routers.gonic.rule=Host(`gonic.${builtins.readFile config.sops.secrets.domain_name.path}`)"
          "-l=traefik.http.services.gonic.loadbalancer.server.port=4747"
        ];
      };
    };
  };
}