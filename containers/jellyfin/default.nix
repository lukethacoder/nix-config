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