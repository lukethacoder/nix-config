{ vars, pkgs, ... }:
let
  # Copyparty Configuration
  copypartyConfig = pkgs.writeText "copyparty.conf" ''
    [global]
      e2dsa  # enable file indexing and filesystem scanning
      e2ts   # enable multimedia indexing
      ansi   # enable colors in log messages (both in logfiles and stdout)

      # q, lo: /cfg/log/%Y-%m%d.log   # log to file instead of docker
      deps

      # allow changable passwords for users
      chpw

      # enable password hashing
      ah-alg: argon2

      # p: 3939          # listen on another port
      # ipa: 10.89.      # only allow connections from 10.89.*
      # df: 16           # stop accepting uploads if less than 16 GB free disk space
      ver              # show copyparty version in the controlpanel
      # grid             # show thumbnails/grid-view by default
      # theme: 2         # monokai
      name: LukeDrive  	 # change the server-name that's displayed in the browser
      # stats, nos-dup   # enable the prometheus endpoint, but disable the dupes counter (too slow)
      no-robots, force-js  # make it harder for search engines to read your server
      rproxy: -1
      xff-src: lan

    [accounts]
      # password should be changed by the user by visiting drive.nah.bz/?h
      luke: 1234  # username: password

    [/]            # create a volume at "/" (the webroot), which will
      /w           # share /w (the docker data volume)
      accs:
        # rw: *      # everyone gets read-write access, but
        rwmda: luke  # the user "luke" gets read-write-move-delete-admin
  '';
in
{
  # Create a copyparty.conf file
  systemd.services."podman-copyparty" = {
    preStart = ''
      mkdir -p ${vars.serviceConfigRoot}/copyparty/config
      cp ${copypartyConfig} ${vars.serviceConfigRoot}/copyparty/config/copyparty.conf
      chown share:share ${vars.serviceConfigRoot}/copyparty/config/copyparty.conf
      chmod 0644 ${vars.serviceConfigRoot}/copyparty/config/copyparty.conf
    '';
  };

  # TODO: configure prometheus/grafana

  homelab.services.copyparty = {
    # using copyparty/iv instead of the default copyparty/ac for RAW thumbnail support
    image = "copyparty/iv:latest";
    subdomain = "drive";
    port = 3923;
    publishPorts = [ "3923:3923" ];
    dirs = [
      "${vars.serviceConfigRoot}/copyparty/config"
      "${vars.serviceConfigRoot}/copyparty/data"
    ];
    volumes = [
      # the copyparty config folder
      "${vars.serviceConfigRoot}/copyparty/config:/cfg:z"

      # where the data is stored
      "${vars.serviceConfigRoot}/copyparty/data:/w:z"
    ];
    env = {
      # enable mimalloc by replacing "NOPE" with "2" for a nice speed-boost (will use twice as much ram)
      LD_PRELOAD = "/usr/lib/libmimalloc-secure.so.NOPE";

      # ensures log-messages are not delayed (but can reduce speed a tiny bit)
      PYTHONUNBUFFERED = "1";
    };
    extraPodmanArgs = [
      "-l=traefik.entryPoints.web.transport.respondingTimeouts.readTimeout=0s"
    ];
    homepage = {
      group = "Services";
      name = "copyparty";
      icon = "https://raw.githubusercontent.com/9001/copyparty/hovudstraum/docs/logo.svg";
      description = "Files n things";
    };
  };
}
