{ vars, ... }:
{
  homelab.services.homeassistant = {
    image = "homeassistant/home-assistant:stable";
    subdomain = "homeassistant";
    port = 8123;
    publishPorts = [
      "127.0.0.0:8123:8123"
    ];
    dirs = [
      "${vars.serviceConfigRoot}/homeassistant"
    ];
    volumes = [
      "${vars.serviceConfigRoot}/homeassistant:/config"
      "/etc/localtime:/localtime:ro"
      "/run/dbus:/run/dbus:ro"
    ];
    # data on disk is owned by uid 1000; normalize to the share identity later
    user = { uid = 1000; gid = 1000; };
    extraPodmanArgs = [
      "--network=host"
      "--privileged"
    ];
    homepage = {
      group = "Services";
      name = "Home Assistant";
      icon = "home-assistant.svg";
      description = "Home Assistant";
      widget = {
        type = "homeassistant";
        url = "https://homeassistant.${vars.domainName}";
      };
    };
  };
}
