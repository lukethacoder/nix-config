{ config, vars, ... }:
let directories = [
  "${vars.serviceConfigRoot}/jellyfin"
  "${vars.mainArray}/Media/TV"
  "${vars.mainArray}/Media/Movies"
];
in {
  systemd.tmpfiles.rules = map (x: "d ${x} 0775 share share - -") directories;

  virtualisation.oci-containers = {
    containers = {
      jellyfin = {
        image = "lscr.io/linuxserver/jellyfin";
        autoStart = true;
        extraOptions = [
          "--device=/dev/dri:/dev/dri"
          # TODO: add traefik and homepage config
        ];
        volumes = [
          "${vars.mainArray}/Media/TV:/data/tvshows"
          "${vars.mainArray}/Media/Movies:/data/movies"
          "${vars.serviceConfigRoot}/jellyfin:/config"
        ];
        environment = {
          TZ = vars.timeZone;
          PUID = "994";
          UMASK = "002";
          GUID = "993";
        };
      };
    };
  };
}