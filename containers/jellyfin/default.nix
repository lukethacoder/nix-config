{ config, vars, pkgs, ... }:
let directories = [
  "${vars.serviceConfigRoot}/jellyfin"
  "${vars.mainArray}/Media/TV"
  "${vars.mainArray}/Media/Movies"
];
in {
  systemd.tmpfiles.rules = map (x: "d ${x} 0775 share share - -") directories;

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override {
      enableHybridCodec = true;
    };
  };
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      vaapiVdpau
      intel-compute-runtime
      # vpl-gpu-rt # QSV on 11th gen or newer
      intel-media-sdk # QSV up to 11th gen
    ];
  };

  virtualisation.oci-containers = {
    containers = {
      jellyfin = {
        image = "lscr.io/linuxserver/jellyfin";
        autoStart = true;
        ports = [ "8096:8096" ];
        extraOptions = [
          "--device=/dev/dri:/dev/dri"
          "-l=traefik.enable=true"
          "-l=traefik.http.routers.jellyfin.rule=Host(`jellyfin.${builtins.readFile config.sops.secrets.domain_name.path}`)"
          "-l=traefik.http.services.jellyfin.loadbalancer.server.port=8096"
          "-l=homepage.group=Media"
          "-l=homepage.name=Jellyfin"
          "-l=homepage.icon=jellyfin.svg"
          "-l=homepage.href=https://jellyfin.${builtins.readFile config.sops.secrets.domain_name.path}"
          "-l=homepage.description=Media player"
          "-l=homepage.widget.type=jellyfin"
          "-l=homepage.widget.key={{HOMEPAGE_FILE_JELLYFIN_KEY}}"
          "-l=homepage.widget.url=http://jellyfin:8096"
          "-l=homepage.widget.enableBlocks=true"
        ];
        volumes = [
          "${vars.mainArray}/Media/TV:/data/tvshows"
          "${vars.mainArray}/Media/Movies:/data/movies"
          "${vars.serviceConfigRoot}/jellyfin:/config"
        ];
        environment = {
          TZ = config.sops.secrets.time_zone.path;
          PUID = "994";
          UMASK = "002";
          GUID = "993";
        };
      };
    };
  };
}