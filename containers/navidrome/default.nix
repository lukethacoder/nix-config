{ config, pkgs, vars, ... }:
let
  VERSION = "0.63.1";
  sharedEnv = {
    ND_SCANSCHEDULE = "1h";
    ND_LOGLEVEL = "info";
    ND_SESSIONTIMEOUT = "24h";
    ND_LASTFM_ENABLED = "true";
  };

  # Navidrome discovers plugins as raw .ndp packages in the plugins folder
  # (extracted directories are ignored) and registers them in its DB; each
  # plugin still has to be enabled and granted library access in the UI.
  ARTIST_NFO_VERSION = "1.3.0";
  navidromePlugins = pkgs.runCommand "navidrome-plugins" { } ''
    mkdir $out
    # Reads artist biography/images from Kodi-style <artist>/artist.nfo files in the library.
    # https://github.com/metalheim/navidrome-plugin-artist-nfo-metadata
    cp ${pkgs.fetchurl {
      url = "https://github.com/metalheim/navidrome-plugin-artist-nfo-metadata/releases/download/v${ARTIST_NFO_VERSION}/artist-nfo-metadata.ndp";
      hash = "sha256-VNfMDJQXX4q/n14Z0QOevO+AhaogoBj/WWb3iycIzok=";
    }} $out/artist-nfo-metadata.ndp
  '';
in {
  homelab.services.navidrome = {
    image = "deluan/navidrome:${VERSION}";
    subdomain = "navidrome";
    port = 4533;
    publishPorts = [ "4533:4533" ];
    dirs = [
      "${vars.serviceConfigRoot}/navidrome"
      "${vars.mainArray}/Media/Music"
      "${vars.mainArray}/Media/Music/Music"
    ];
    volumes = [
      "${vars.serviceConfigRoot}/navidrome:/data"
      "${vars.mainArray}/Media/Music/Music:/music:ro"
      "${navidromePlugins}:/plugins:ro"
    ];
    # data on disk is owned by uid 1000; normalize to the share identity later
    user = { uid = 1000; gid = 1000; };
    env = sharedEnv // {
      ND_BASEURL = "http://navidrome.${vars.domainName}";
      ND_PROMETHEUS_ENABLED = "true";
      ND_PLUGINS_ENABLED = "true";
      ND_PLUGINS_FOLDER = "/plugins";
      ND_AGENTS = "artist-nfo-metadata,lastfm";
    };
    environmentFiles = [
      config.sops.templates."navidrome-env".path
    ];
    homepage = {
      group = "Media";
      name = "Navidrome";
      icon = "navidrome.svg";
      description = "Media player";
      widget = {
        type = "navidrome";
        user = "{{HOMEPAGE_FILE_NAVIDROME_USERNAME}}";
        token = "{{HOMEPAGE_FILE_NAVIDROME_TOKEN}}";
        salt = "{{HOMEPAGE_FILE_NAVIDROME_SALT}}";
        url = "https://navidrome.${vars.domainName}";
      };
    };
  };

  # Separate instance purely for DJ Mixes
  # TODO: multi libraries are now supported - migrate when possible
  homelab.services.navidrome_mixes = {
    image = "deluan/navidrome:${VERSION}";
    subdomain = "mixes";
    port = 4533;
    publishPorts = [ "4534:4533" ];
    dirs = [
      "${vars.serviceConfigRoot}/navidrome-mixes"
      "${vars.mainArray}/Media/Music/Mixes"
    ];
    volumes = [
      "${vars.serviceConfigRoot}/navidrome-mixes:/data"
      "${vars.mainArray}/Media/Music/Mixes:/music:ro"
    ];
    user = { uid = 1000; gid = 1000; };
    env = sharedEnv // {
      ND_BASEURL = "http://mixes.${vars.domainName}";
      # ND_LASTFM_APIKEY = config.sops.secrets."lastfm/api_key".path;
      # ND_LASTFM_SECRET = config.sops.secrets."lastfm/api_secret".path;
    };
    environmentFiles = [
      config.sops.templates."navidrome-env".path
    ];
    homepage = {
      group = "Media";
      name = "Navidrome Mixes";
      icon = "https://simpleicons.org/icons/pioneerdj.svg";
      description = "Media player";
      widget = {
        type = "navidrome";
        user = "{{HOMEPAGE_FILE_NAVIDROME_USERNAME}}";
        token = "{{HOMEPAGE_FILE_NAVIDROME_TOKEN}}";
        salt = "{{HOMEPAGE_FILE_NAVIDROME_SALT}}";
        url = "https://mixes.${vars.domainName}";
      };
    };
  };
}
