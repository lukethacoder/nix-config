{ vars, pkgs, ... }:
let
  # adjust to bump the version when required
  jellyfinVersion = "10.11.11";
in {
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
      libva-vdpau-driver
      intel-compute-runtime
      # vpl-gpu-rt # QSV on 11th gen or newer
    ];
  };

  # TODO: post-intall, set the `EnableMetrics` flag to `true` in the `/jellyfin/system.xml` file

  homelab.services.jellyfin = {
    image = "lscr.io/linuxserver/jellyfin:${jellyfinVersion}";
    subdomain = "jellyfin";
    port = 8096;
    publishPorts = [ "8096:8096" ];
    dirs = [
      "${vars.serviceConfigRoot}/jellyfin"
      "${vars.mainArray}/Media/TV"
      "${vars.mainArray}/Media/Movies"
    ];
    volumes = [
      "${vars.mainArray}/Media/TV:/data/tvshows"
      "${vars.mainArray}/Media/Movies:/data/movies"
      "${vars.serviceConfigRoot}/jellyfin:/config"
    ];
    env = {
      UMASK = "002";
    };
    extraPodmanArgs = [
      "--device=/dev/dri:/dev/dri"
    ];
    homepage = {
      group = "Media";
      name = "Jellyfin";
      icon = "jellyfin.svg";
      description = "Media player";
      widget = {
        type = "jellyfin";
        key = "{{HOMEPAGE_FILE_JELLYFIN_KEY}}";
        url = "http://jellyfin:8096";
        enableBlocks = "true";
      };
    };
  };
}
