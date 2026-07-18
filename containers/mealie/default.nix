{ vars, ... }:
{
  homelab.services.mealie = {
    image = "ghcr.io/mealie-recipes/mealie:v3.19.2";
    subdomain = "cook";
    port = 9000;
    publishPorts = [ "9925:9000" ];
    dirs = [ "${vars.serviceConfigRoot}/mealie" ];
    volumes = [ "${vars.serviceConfigRoot}/mealie:/app/data" ];
    # data on disk is owned by uid 1000; normalize to the share identity later
    user = { uid = 1000; gid = 1000; };
    env = {
      BASE_URL = "https://cook.${vars.domainName}";
    };
    homepage = {
      group = "Media";
      name = "Mealie";
      icon = "mealie.svg";
      description = "Recipes";
      widget = {
        type = "mealie";
        token = "{{HOMEPAGE_FILE_MEALIE_TOKEN}}";
        version = "2";
        url = "https://cook.${vars.domainName}";
      };
    };
  };
}
