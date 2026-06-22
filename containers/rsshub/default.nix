{ config, vars, pkgs, ... }:
let
  rsshubVersion = "0.1.2";

  rootDir = "${vars.serviceConfigRoot}/rsshub";
  redisDir = "${rootDir}/redis";

  directories = [
    rootDir
    redisDir
  ];
in {
  systemd.tmpfiles.rules = map (x: "d ${x} 0775 share share - -") directories;

  virtualisation.oci-containers = {
    containers = {
      rsshub = {
        autoStart = true;
        image = "ghcr.io/lukethacoder/rsshub-mini:${rsshubVersion}";
        dependsOn = [
          "rsshub-redis"
          "rsshub-browserless"
        ];
        environment = {
          TZ = vars.timeZone;
          NODE_ENV = "production";
          CACHE_TYPE = "redis";
          REDIS_URL = "redis://rsshub-redis:6379/";
          PLAYWRIGHT_WS_ENDPOINT = "ws://rsshub-browserless:3000/playwright/chromium";
        };
        extraOptions = [
          "--pull=newer"
          "-l=traefik.enable=true"
          "-l=traefik.http.routers.rsshub.rule=Host(`rsshub.${vars.domainName}`)"
          "-l=traefik.http.services.rsshub.loadbalancer.server.port=1200"
          "-l=homepage.group=Services"
          "-l=homepage.name=RSSHub"
          "-l=homepage.icon=rsshub.png"
          "-l=homepage.href=https://rsshub.${vars.domainName}"
          "-l=homepage.description=RSS feed generator"
        ];
      };

      rsshub-browserless = {
        autoStart = true;
        image = "ghcr.io/browserless/chromium";
        extraOptions = [
          "--pull=newer"
          "--ulimit=core=0:0"
        ];
      };

      rsshub-redis = {
        autoStart = true;
        image = "redis:alpine";
        volumes = [
          "${redisDir}:/data"
        ];
        extraOptions = [
          "--pull=newer"
        ];
      };
    };
  };
}
