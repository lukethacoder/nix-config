{ config, vars, ... }:
{
  # acme.json must exist with tight permissions before traefik starts
  systemd.tmpfiles.rules = [
    "f ${vars.serviceConfigRoot}/traefik/acme.json 0600 share share - -"
  ];

  homelab.services.traefik = {
    image = "traefik";
    subdomain = "proxy";
    port = 8080;
    publishPorts = [
      "443:443"
      "80:80"
    ];
    dirs = [
      "${vars.serviceConfigRoot}/traefik"
    ];
    volumes = [
      "/var/run/podman/podman.sock:/var/run/docker.sock:ro"
      "${vars.serviceConfigRoot}/traefik/acme.json:/acme.json"
    ];
    # image doesn't consume PUID/PGID
    user = null;
    environmentFiles = [
      config.sops.templates."traefik-env".path
    ];
    extraContainerConfig = {
      cmd = [
        "--api.insecure=true"
        "--api.debug=true"
        "--providers.docker=true"
        "--providers.docker.exposedbydefault=false"
        "--certificatesresolvers.letsencrypt.acme.dnschallenge=true"
        "--certificatesresolvers.letsencrypt.acme.storage=/acme.json"
        "--certificatesresolvers.letsencrypt.acme.dnschallenge.provider=cloudflare"
        "--certificatesresolvers.letsencrypt.acme.dnschallenge.resolvers=8.8.8.8:53"
        "--certificatesresolvers.letsencrypt.acme.email=dev@lukesecomb.digital"
        # HTTP
        "--entrypoints.web.address=:80"
        "--entrypoints.web.http.redirections.entrypoint.to=websecure"
        "--entrypoints.web.http.redirections.entrypoint.scheme=https"
        "--entrypoints.websecure.address=:443"
        # HTTPS
        "--entrypoints.websecure.http.tls=true"
        "--entrypoints.websecure.http.tls.certResolver=letsencrypt"
        "--entrypoints.websecure.http.tls.domains[0].main=${vars.domainName}"
        "--entrypoints.websecure.http.tls.domains[0].sans=*.${vars.domainName}"
      ];
    };
    homepage = {
      group = "Services";
      name = "Traefik";
      icon = "traefik-proxy.svg";
      description = "Reverse proxy";
      widget = {
        type = "traefik";
        url = "http://traefik:8080";
      };
    };
  };
}
