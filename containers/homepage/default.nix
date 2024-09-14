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
          "-l=traefik.enable=true"
          # "-l=traefik.http.routers.home.rule=Host(`${config.age.secrets.domainName.path}`)"
          "-l=traefik.http.services.home.loadbalancer.server.port=3000"
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
          "${config.sops.secrets."jellyfin/api_key".path}:/app/config/jellyfin.key"
          "${config.sops.secrets."navidrome/username".path}:/app/config/navidrome-username.key"
          "${config.sops.secrets."navidrome/token".path}:/app/config/navidrome-token.key"
          "${config.sops.secrets."navidrome/salt".path}:/app/config/navidrome-salt.key"
        ];
        environment = {
          TZ = "${config.sops.secrets.time_zone.path}";
          # HOMEPAGE_FILE_SONARR_KEY = "/app/config/sonarr.key";
          # HOMEPAGE_FILE_RADARR_KEY = "/app/config/radarr.key";
          HOMEPAGE_FILE_JELLYFIN_KEY = "/app/config/jellyfin.key";
          HOMEPAGE_FILE_NAVIDROME_USERNAME = "/app/config/navidrome-username.key";
          HOMEPAGE_FILE_NAVIDROME_TOKEN = "/app/config/navidrome-token.key";
          HOMEPAGE_FILE_NAVIDROME_SALT = "/app/config/navidrome-salt.key";
        };
        # environmentFiles = [
        #   config.age.secrets.paperless.path
        # ];
      };
    };
};
}