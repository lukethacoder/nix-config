{ config, vars, ... }:
let
  directories = [
    "${vars.serviceConfigRoot}/copyparty/config"
    "${vars.serviceConfigRoot}/copyparty/data"
  ];
in
{
  systemd.tmpfiles.rules = map (x: "d ${x} 0775 share share - -") directories;

  # TODO: dynamically pull password from SOPS
  # # Create a copyparty.conf file
  environment.etc."${vars.serviceConfigRoot}/copyparty/config/copyparty.conf" = {
    text = ''
      [global]
        e2dsa  # enable file indexing and filesystem scanning
        e2ts   # enable multimedia indexing
        ansi   # enable colors in log messages (both in logfiles and stdout)

        # q, lo: /cfg/log/%Y-%m%d.log   # log to file instead of docker
        deps

        # p: 3939          # listen on another port
        # ipa: 10.89.      # only allow connections from 10.89.*
        # df: 16           # stop accepting uploads if less than 16 GB free disk space
        ver              # show copyparty version in the controlpanel
        # grid             # show thumbnails/grid-view by default
        # theme: 2         # monokai
        name: LukeDrive  	 # change the server-name that's displayed in the browser
        # stats, nos-dup   # enable the prometheus endpoint, but disable the dupes counter (too slow)
        no-robots, force-js  # make it harder for search engines to read your server

      [accounts]
        luke: test  # username: password

      [/]            # create a volume at "/" (the webroot), which will
        /w           # share /w (the docker data volume)
        accs:
          # rw: *      # everyone gets read-write access, but
          rwmda: luke  # the user "luke" gets read-write-move-delete-admin
    '';
  }

  # TODO: configure prometheus/grafana

  virtualisation.oci-containers = {
    containers = {
      deluge = {
        # using copyparty/iv instead of the default copyparty/ac for RAW thumbnail support
        image = "copyparty/iv:latest";
        autoStart = true;
        ports = "3923:3923";
        volumes = [
          # the copyparty config folder
          "${vars.serviceConfigRoot}/copyparty/config:/cfg:z"

          # where the data is stored
          "${vars.serviceConfigRoot}/copyparty/data:/w:z"
        ];
        extraOptions = [
          "--pull=newer"
          "-l=homepage.group=Services"
          "-l=homepage.name=copyparty"
          "-l=homepage.icon=https://raw.githubusercontent.com/9001/copyparty/hovudstraum/docs/logo.svg"
          "-l=homepage.href=https://drive.${vars.domainName}"
          "-l=homepage.description=Files n things"
        ];
        environment = {
          TZ = vars.timeZone;
          PUID = "994";
          GUID = "993";

          # enable mimalloc by replacing "NOPE" with "2" for a nice speed-boost (will use twice as much ram)
          LD_PRELOAD = "/usr/lib/libmimalloc-secure.so.NOPE";

          # ensures log-messages are not delayed (but can reduce speed a tiny bit)
          PYTHONUNBUFFERED = 1;
        };
      };
    };
  };
}
