{ vars, ... }:
let
  rsshubVersion = "0.1.2";

  rootDir = "${vars.serviceConfigRoot}/rsshub";
  redisDir = "${rootDir}/redis";
in {
  homelab.services.rsshub = {
    image = "ghcr.io/lukethacoder/rsshub-mini:${rsshubVersion}";
    subdomain = "rsshub";
    port = 1200;
    dirs = [
      rootDir
      redisDir
    ];
    # image doesn't consume PUID/PGID
    user = null;
    env = {
      NODE_ENV = "production";
      CACHE_TYPE = "redis";
      REDIS_URL = "redis://rsshub-redis:6379/";
      PLAYWRIGHT_WS_ENDPOINT = "ws://rsshub-browserless:3000/playwright/chromium";
    };
    extraContainerConfig = {
      dependsOn = [
        "rsshub-redis"
        "rsshub-browserless"
      ];
    };
    homepage = {
      group = "Services";
      name = "RSSHub";
      icon = "rsshub.png";
      description = "RSS feed generator";
    };
  };

  # Sidecars
  virtualisation.oci-containers.containers = {
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
}
