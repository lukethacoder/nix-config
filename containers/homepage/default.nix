{ config, inputs, vars, pkgs, ... }:
let
  directories = [
    "${vars.serviceConfigRoot}/homepage"
    "${vars.serviceConfigRoot}/homepage/config"
  ];

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

  systemd.tmpfiles.rules = map (x: "d ${x} 0775 share share - -") directories;

  virtualisation.oci-containers = {
    containers = {
      homepage = {
        image = "ghcr.io/gethomepage/homepage:latest";
        autoStart = true;
        extraOptions = [
          "--pull=newer"
          "-l=traefik.enable=true"
          "-l=traefik.http.routers.homepage.rule=Host(`home.lukethacoder.duckdns.org`)"
          "-l=traefik.http.services.homepage.loadbalancer.server.port=3000"

          # Extra Services

          # AdGuard Home (Router)
          "-l=homepage.group=Services"
          "-l=homepage.name=AdGuard"
          "-l=homepage.icon=adguard-home.svg"
          "-l=homepage.href=http://192.168.8.1:3000"
          "-l=homepage.description=DNS and Adblocking"
          "-l=homepage.widget.url=http://192.168.8.1:3000"
          "-l=homepage.widget.type=adguard"
          "-l=homepage.widget.username={{HOMEPAGE_FILE_ADGUARD_USERNAME}}"
          "-l=homepage.widget.password={{HOMEPAGE_FILE_ADGUARD_PASSWORD}}"
          "-l=homepage.widget.fields=['queries', 'blocked', 'filtered', 'latency']"
        ];
        ports = [ "3000:3000" ];
        volumes = [
          "${vars.serviceConfigRoot}/homepage/config:/app/config"
          "${homepageSettings.docker}:/app/config/docker.yaml"
          "${homepageSettings.bookmarks}:/app/config/bookmarks.yaml"
          "${homepageSettings.services}:/app/config/services.yaml"
          "${homepageSettings.settings}:/app/config/settings.yaml"
          "${homepageSettings.widgets}:/app/config/widgets.yaml"
          "${homepageCustomCss}:/app/config/custom.css"
          "/var/run/podman/podman.sock:/var/run/docker.sock:ro"
          # "${config.age.secrets.sonarrApiKey.path}:/app/config/sonarr.key"
          # "${config.age.secrets.radarrApiKey.path}:/app/config/radarr.key"
          "${config.sops.secrets."adguard/username".path}:/app/config/adguard-username.key"
          "${config.sops.secrets."adguard/password".path}:/app/config/adguard-password.key"
          "${config.sops.secrets."immich/api_key".path}:/app/config/immich.key"
          "${config.sops.secrets."jellyfin/api_key".path}:/app/config/jellyfin.key"
          "${config.sops.secrets."navidrome/username".path}:/app/config/navidrome-username.key"
          "${config.sops.secrets."navidrome/token".path}:/app/config/navidrome-token.key"
          "${config.sops.secrets."navidrome/salt".path}:/app/config/navidrome-salt.key"
          "${config.sops.secrets."qbittorrent/username".path}:/app/config/qbittorrent-username.key"
          "${config.sops.secrets."qbittorrent/password".path}:/app/config/qbittorrent-password.key"
        ];
        environment = {
          TZ = vars.timeZone;
          HOMEPAGE_ALLOWED_HOSTS = "home.${vars.domainName}";
          HOMEPAGE_FILE_IMMICH_KEY = "/app/config/immich.key";
          HOMEPAGE_FILE_JELLYFIN_KEY = "/app/config/jellyfin.key";
          HOMEPAGE_FILE_NAVIDROME_USERNAME = "/app/config/navidrome-username.key";
          HOMEPAGE_FILE_NAVIDROME_TOKEN = "/app/config/navidrome-token.key";
          HOMEPAGE_FILE_NAVIDROME_SALT = "/app/config/navidrome-salt.key";
          HOMEPAGE_FILE_ADGUARD_USERNAME = "/app/config/adguard-username.key";
          HOMEPAGE_FILE_ADGUARD_PASSWORD = "/app/config/adguard-password.key";
          HOMEPAGE_FILE_QBITTORRENT_USERNAME = "/app/config/qbittorrent-username.key";
          HOMEPAGE_FILE_QBITTORRENT_PASSWORD = "/app/config/qbittorrent-password.key";
        };
        # environmentFiles = [
        #   config.age.secrets.paperless.path
        # ];
      };
    };
};
}