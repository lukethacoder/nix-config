{ config, vars, pkgs, ... }:
let 
  directories = [
    "${vars.serviceConfigRoot}/jellyfin"
    "${vars.mainArray}/Media/TV"
    "${vars.mainArray}/Media/Movies"
  ];
  # adjust to bump the version when required
  jellyfinVersion = "10.11.5";
in {
  systemd.tmpfiles.rules = map (x: "d ${x} 0775 share share - -") directories;

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override {
      enableHybridCodec = true;
    };
  };
  hardware.graphics = {
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

  # TODO: post-intall, set the `EnableMetrics` flag to `true` in the `/jellyfin/system.xml` file

  virtualisation.oci-containers = {
    containers = {
      jellyfin = {
        image = "lscr.io/linuxserver/jellyfin:${jellyfinVersion}";
        autoStart = true;
        ports = [ "8096:8096" ];
        extraOptions = [
          "--device=/dev/dri:/dev/dri"
          "-l=traefik.enable=true"
          "-l=traefik.http.routers.jellyfin.rule=Host(`jellyfin.${vars.domainName}`)"
          "-l=traefik.http.services.jellyfin.loadbalancer.server.port=8096"
          "-l=homepage.group=Media"
          "-l=homepage.name=Jellyfin"
          "-l=homepage.icon=jellyfin.svg"
          "-l=homepage.href=https://jellyfin.${vars.domainName}"
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