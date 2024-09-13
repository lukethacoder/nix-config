{ config, vars, pkgs, ... }:
{
  virtualisation.oci-containers = {
    containers = {
      lms = {
        image = "epoupon/lms";
        autoStart = true;
        ports = [ "5082:5082" ];
        environment = {
          TZ = config.sops.secrets.time_zone.path;
        };
        volumes = [
          "${vars.serviceConfigRoot}/lms:/var/lms:rw"
          "${vars.mainArray}/Media/Music/Music:/music:ro"
        ];
        extraOptions = [
          # "--device=/dev/snd:/dev/snd"
          "-l=traefik.enable=true"
          "-l=traefik.http.routers.lms.rule=Host(`lms.${builtins.readFile config.sops.secrets.domain_name.path}`)"
          "-l=traefik.http.services.lms.loadbalancer.server.port=5082"
        ];
      };
    };
  };
}