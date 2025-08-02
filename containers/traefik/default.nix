{ config, lib, vars, networksLocal, ... }:
let
  internalIP = (lib.lists.findSingle (x: x.hostname == "${config.networking.hostName}") { ip-address = "${networksLocal.networks.lan.cidr}"; } "0.0.0.0" networksLocal.networks.lan.reservations).ip-address;
  directories = [
    "${vars.serviceConfigRoot}/traefik"
  ];
  files = [
    "${vars.serviceConfigRoot}/traefik/acme.json"
  ];
in
{
  systemd.tmpfiles.rules = map (x: "d ${x} 0775 share share - -") directories ++ map (x: "f ${x} 0600 share share - -") files;
  virtualisation.oci-containers = {
    containers = {
      traefik = {
        image = "traefik";
        autoStart = true;
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
        extraOptions = [
          # Proxying Traefik itself
          "-l=traefik.enable=true"
          "-l=traefik.http.routers.traefik.rule=Host(`proxy.${vars.domainName}`)"
          "-l=traefik.http.services.traefik.loadbalancer.server.port=8080"
          "-l=homepage.group=Services"
          "-l=homepage.name=Traefik"
          "-l=homepage.icon=traefik-proxy.svg"
          "-l=homepage.href=https://proxy.${vars.domainName}"
          "-l=homepage.description=Reverse proxy"
          "-l=homepage.widget.type=traefik"
          "-l=homepage.widget.url=http://traefik:8080"
        ];
        ports = [
          "443:443"
          "80:80"
        ];
        environmentFiles = [
          config.sops.templates."traefik-env".path
        ];
        volumes = [
          "/var/run/podman/podman.sock:/var/run/docker.sock:ro"
          "${vars.serviceConfigRoot}/traefik/acme.json:/acme.json"
        ];
      };
    };
  };
}
