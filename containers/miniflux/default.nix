{ vars, ... }:
{
  homelab.services.miniflux = {
    image = "miniflux/miniflux:2.2.16";
    subdomain = "rss";
    port = 8080;
    dirs = [
      "${vars.serviceConfigRoot}/miniflux"
    ];
    # image doesn't consume PUID/PGID
    user = null;
    env = {
      BASE_URL = "https://miniflux.${vars.domainName}";
      DATABASE_URL = "postgres://miniflux:test@miniflux-db/miniflux?sslmode=disable";
      RUN_MIGRATIONS = "1";
      CREATE_ADMIN = "1";
      ADMIN_USERNAME = "admin";
      ADMIN_PASSWORD = "test123";
      FETCH_YOUTUBE_WATCH_TIME = "1";
      METRICS_COLLECTOR = "1";
      METRICS_ALLOWED_NETWORKS = "0.0.0.0/0";
    };
    extraContainerConfig = {
      dependsOn = [
        "miniflux-db"
      ];
    };
    homepage = {
      group = "Services";
      name = "miniflux";
      icon = "miniflux";
      description = "RSS";
      widget = {
        type = "miniflux";
        password = "test";
        url = "https://rss.${vars.domainName}";
      };
    };
  };

  # Sidecar
  virtualisation.oci-containers.containers.miniflux-db = {
    image = "postgres:18";
    autoStart = true;
    volumes = [
      "${vars.serviceConfigRoot}/miniflux:/var/lib/postgresql"
    ];
    environment = {
      TZ = vars.timeZone;
      POSTGRES_USER = "miniflux";
      POSTGRES_PASSWORD = "test";
      POSTGRES_DB = "miniflux";
    };
  };
}
