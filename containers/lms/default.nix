{ config, vars, pkgs, ... }:
let directories = [
  "${vars.serviceConfigRoot}/lms"
  "${vars.mainArray}/Media/Music"
];
in {
  system.userActivationScripts.lms-data.text = ''
    mkdir -p ${vars.serviceConfigRoot}/lms \
      ${vars.mainArray}/Media/Music/Music
  '';

  systemd.tmpfiles.rules = map (x: "d ${x} 0775 share share - -") directories;

  virtualisation.oci-containers = {
    containers = {
      lms = {
        image = "docker.io/epoupon/lms:latest";
        autoStart = true;
        ports = [ "5082:5082" ];
        # user = "1000:100";
        environment = {
          TZ = config.sops.secrets.time_zone.path;
          # PUID = "1000";
          # PGID = "1000";
        };
        volumes = [
          "${vars.mainArray}/Media/Music/Music:/music:ro"
          "${vars.serviceConfigRoot}/lms:/var/lms" # :rw
        ];
        # cmd = [
        #   "--user 1000:100"
        #   "-v ${vars.serviceConfigRoot}/lms:/var/lms:rw"
        #   "-v ${vars.mainArray}/Media/Music/Music:/music:ro"
        # ];
        # extraOptions = [
        #   # "--device=/dev/snd:/dev/snd"
        #   "--user luke:share"
        #   "-v=${vars.serviceConfigRoot}/lms:/var/lms:rw"
        #   "-v=${vars.mainArray}/Media/Music/Music:/music:ro"
        #   "-l=traefik.enable=true"
        #   "-l=traefik.http.routers.lms.rule=Host(`lms.${builtins.readFile config.sops.secrets.domain_name.path}`)"
        #   "-l=traefik.http.services.lms.loadbalancer.server.port=5082"
        # ];
      };
    };
  };
}