{ config, vars, pkgs, ... }:
let
  settingsFormat = pkgs.formats.yaml { };
  homepageSettings = {
    docker = settingsFormat.generate "docker.yaml" (import ./docker.nix);
    services = pkgs.writeTextFile {
      name = "services.yaml";
      text = builtins.readFile ./services.yaml;
    };
    settings = pkgs.writeTextFile {
      name = "settings.yaml";
      text = builtins.readFile ./settings.yaml;
    };
    bookmarks = settingsFormat.generate "bookmarks.yaml" (import ./bookmarks.nix);
    widgets = pkgs.writeTextFile {
      name = "widgets.yaml";
      text = builtins.readFile ./widgets.yaml;
    };
  };
  homepageCustomCss = pkgs.writeTextFile {
    name = "custom.css";
    text = builtins.readFile ./custom.css;
  };
in {
  environment.systemPackages = with pkgs; [ glances ];

  networking.firewall.allowedTCPPorts = [ 61208 ];

  systemd.services.glances = {
    description = "Glances";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.glances}/bin/glances -w";
      Type = "simple";
    };
  };

  homelab.services.homepage = {
    image = "ghcr.io/gethomepage/homepage:latest";
    subdomain = "home";
    port = 3000;
    publishPorts = [ "3000:3000" ];
    dirs = [
      "${vars.serviceConfigRoot}/homepage"
      "${vars.serviceConfigRoot}/homepage/config"
    ];
    volumes = [
      "${vars.serviceConfigRoot}/homepage/config:/app/config"
      "${homepageSettings.docker}:/app/config/docker.yaml"
      "${homepageSettings.bookmarks}:/app/config/bookmarks.yaml"
      "${homepageSettings.services}:/app/config/services.yaml"
      "${homepageSettings.settings}:/app/config/settings.yaml"
      "${homepageSettings.widgets}:/app/config/widgets.yaml"
      "${homepageCustomCss}:/app/config/custom.css"
      "/var/run/podman/podman.sock:/var/run/docker.sock:ro"
      "${config.sops.secrets."adguard/username".path}:/app/config/adguard-username.key"
      "${config.sops.secrets."adguard/password".path}:/app/config/adguard-password.key"
      "${config.sops.secrets."immich/api_key".path}:/app/config/immich.key"
      "${config.sops.secrets."jellyfin/api_key".path}:/app/config/jellyfin.key"
      "${config.sops.secrets."mealie/token".path}:/app/config/mealie-token.key"
      "${config.sops.secrets."navidrome/username".path}:/app/config/navidrome-username.key"
      "${config.sops.secrets."navidrome/token".path}:/app/config/navidrome-token.key"
      "${config.sops.secrets."navidrome/salt".path}:/app/config/navidrome-salt.key"
      "${config.sops.secrets."qbittorrent/username".path}:/app/config/qbittorrent-username.key"
      "${config.sops.secrets."qbittorrent/password".path}:/app/config/qbittorrent-password.key"
    ];
    # image doesn't consume PUID/PGID
    user = null;
    env = {
      HOMEPAGE_ALLOWED_HOSTS = "home.${vars.domainName}";
      HOMEPAGE_FILE_IMMICH_KEY = "/app/config/immich.key";
      HOMEPAGE_FILE_JELLYFIN_KEY = "/app/config/jellyfin.key";
      HOMEPAGE_FILE_MEALIE_TOKEN = "/app/config/mealie-token.key";
      HOMEPAGE_FILE_NAVIDROME_USERNAME = "/app/config/navidrome-username.key";
      HOMEPAGE_FILE_NAVIDROME_TOKEN = "/app/config/navidrome-token.key";
      HOMEPAGE_FILE_NAVIDROME_SALT = "/app/config/navidrome-salt.key";
      HOMEPAGE_FILE_ADGUARD_USERNAME = "/app/config/adguard-username.key";
      HOMEPAGE_FILE_ADGUARD_PASSWORD = "/app/config/adguard-password.key";
      HOMEPAGE_FILE_QBITTORRENT_USERNAME = "/app/config/qbittorrent-username.key";
      HOMEPAGE_FILE_QBITTORRENT_PASSWORD = "/app/config/qbittorrent-password.key";
    };
    # AdGuard Home runs on the router, not as a container, so its dashboard
    # entry piggybacks on the homepage container's own labels
    homepage = {
      group = "Services";
      name = "AdGuard";
      icon = "adguard-home.svg";
      href = "http://192.168.8.1:3000";
      description = "DNS and Adblocking";
      widget = {
        url = "http://192.168.8.1:3000";
        type = "adguard";
        username = "{{HOMEPAGE_FILE_ADGUARD_USERNAME}}";
        password = "{{HOMEPAGE_FILE_ADGUARD_PASSWORD}}";
        fields = "['queries', 'blocked', 'filtered', 'latency']";
      };
    };
  };
}
