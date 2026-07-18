{ config, lib, vars, ... }:
let
  inherit (lib) mkOption types;

  serviceOptions = {
    options = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to run this service.";
      };
      image = mkOption {
        type = types.str;
        description = "Container image, including tag.";
      };
      subdomain = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Subdomain of ${vars.domainName} the service is reachable at. null = not routed by traefik.";
      };
      port = mkOption {
        type = types.nullOr types.port;
        default = null;
        description = "Container port traefik routes to. Required when subdomain is set.";
      };
      publishPorts = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Ports published on the host, podman syntax (\"host:container\").";
      };
      volumes = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
      dirs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Host directories created at boot, owned by the share identity (0775).";
      };
      env = mkOption {
        type = types.attrsOf types.str;
        default = { };
      };
      environmentFiles = mkOption {
        type = types.listOf types.path;
        default = [ ];
        description = "Env files, typically a sops template path.";
      };
      user = mkOption {
        type = types.nullOr (types.submodule {
          options = {
            uid = mkOption { type = types.int; };
            gid = mkOption { type = types.int; };
          };
        });
        default = { inherit (vars.shareUser) uid gid; };
        description = "Identity the container runs as, emitted as PUID/PGID. Defaults to the share identity; null omits PUID/PGID for images that don't consume them.";
      };
      metricsPorts = mkOption {
        type = types.listOf types.port;
        default = [ ];
        description = "Prometheus metrics ports, published 1:1 on the host.";
      };
      homepage = mkOption {
        type = types.nullOr (types.submodule {
          options = {
            group = mkOption { type = types.str; };
            name = mkOption { type = types.str; };
            icon = mkOption { type = types.str; };
            description = mkOption { type = types.str; };
            href = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Defaults to https://<subdomain>.<domain>.";
            };
            widget = mkOption {
              type = types.nullOr (types.attrsOf types.str);
              default = null;
            };
          };
        });
        default = null;
        description = "Dashboard entry; the homepage observer reads these as container labels.";
      };
      extraPodmanArgs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Extra podman flags appended after the generated labels.";
      };
      extraContainerConfig = mkOption {
        type = types.attrs;
        default = { };
        description = "Escape hatch merged over the generated oci-container definition (dependsOn, cmd, ...).";
      };
    };
  };

  enabledServices = lib.filterAttrs (_: s: s.enable) config.homelab.services;

  traefikLabels = name: s:
    lib.optionals (s.subdomain != null) [
      "-l=traefik.enable=true"
      "-l=traefik.http.routers.${name}.rule=Host(`${s.subdomain}.${vars.domainName}`)"
      "-l=traefik.http.services.${name}.loadbalancer.server.port=${toString s.port}"
    ];

  homepageLabels = name: s:
    lib.optionals (s.homepage != null) (
      let
        hp = s.homepage;
        href = if hp.href != null then hp.href else "https://${s.subdomain}.${vars.domainName}";
      in
      [
        "-l=homepage.group=${hp.group}"
        "-l=homepage.name=${hp.name}"
        "-l=homepage.icon=${hp.icon}"
        "-l=homepage.href=${href}"
        "-l=homepage.description=${hp.description}"
      ]
      ++ lib.optionals (hp.widget != null)
        (lib.mapAttrsToList (k: v: "-l=homepage.widget.${k}=${v}") hp.widget)
    );

  mkContainer = name: s:
    {
      image = s.image;
      autoStart = true;
      ports = s.publishPorts
        ++ map (p: "${toString p}:${toString p}") s.metricsPorts;
      volumes = s.volumes;
      environment = {
        TZ = vars.timeZone;
      } // lib.optionalAttrs (s.user != null) {
        PUID = toString s.user.uid;
        PGID = toString s.user.gid;
      } // s.env;
      environmentFiles = s.environmentFiles;
      extraOptions = [ "--pull=newer" ]
        ++ traefikLabels name s
        ++ homepageLabels name s
        ++ s.extraPodmanArgs;
    } // s.extraContainerConfig;
in
{
  options.homelab.services = mkOption {
    type = types.attrsOf (types.submodule serviceOptions);
    default = { };
    description = "Service declarations. Everything needed to run a service is derived from these (see CONTEXT.md).";
  };

  config = {
    virtualisation.oci-containers.containers = lib.mapAttrs mkContainer enabledServices;

    systemd.tmpfiles.rules =
      map (d: "d ${d} 0775 ${vars.shareUser.name} ${vars.shareUser.name} - -")
        (lib.concatMap (s: s.dirs) (lib.attrValues enabledServices));
  };
}
