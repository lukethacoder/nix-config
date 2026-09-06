# Home Assistant Container, plus the Matter and Thread services a Container
# install needs — the official image has no add-ons, so they are managed here.
# All three run on the host network: Matter needs link-local IPv6 and mDNS, and
# neither survives podman's bridge.
#
# Bring-up, in order:
#   1. http://<opslag>:8123 direct, and onboard. Before touching traefik.
#   2. Matter integration -> ws://localhost:5580/ws. The same port serves a web
#      dashboard (node detail, Thread mesh view) on http://localhost:5580/ —
#      loopback-bound, so reach it over an ssh tunnel.
#   3. otbrEnabled = true, then the OpenThread Border Router integration ->
#      http://localhost:8081. The Thread panel should report a preferred network.
#   4. Commission from the phone app, on the same LAN as opslag — Matter
#      commissioning is link-local multicast and does not route across VLANs.
#   5. Reverse proxy last: check both the traefik route and the websocket (the
#      HA UI goes blank on a broken WS while plain HTTP still looks fine).
#      HA must also be told to trust the proxy, in its own configuration.yaml —
#      HA rewrites that file, so it is not templated from nix:
#        http:
#          use_x_forwarded_for: true
#          trusted_proxies: [ <traefik's podman address> ]
#
# Recovery: every service keeps its state on the persist volume, so recreating a
# container costs nothing. services/matter-server holds the Matter fabric and
# services/otbr the Thread credentials — losing either means re-commissioning
# every device. Replacing the radio is only a new `radio.device` path.
{ lib, pkgs, vars, ... }:
let
  homeassistantImage = "docker.io/homeassistant/home-assistant:2026.8.2";
  matterServerImage = "ghcr.io/matter-js/matterjs-server:1.4.0";
  otbrImage = "docker.io/openthread/border-router:latest";

  # OTBR's backbone/infrastructure interface: the LAN NIC that carries IPv6.
  # NOTE: confirm with `ip route get 1.1.1.1` / `ip -br link`.
  lanInterface = "eno2";

  # One switch for the whole Thread stack: the OTBR container, the host sysctls
  # and kernel modules it needs, and the Thread firewall port.
  otbrEnabled = true;

  # Home Assistant Connect ZBT-2, dedicated to Thread — the radio runs one
  # protocol at a time and this one is Thread's.
  #
  # It ships running ZIGBEE firmware and must be reflashed with OpenThread RCP
  # firmware before OTBR can talk to it; see the flasher below. 460800 baud with
  # hardware flow control is the ZBT-2's rate and matches the defaults in Home
  # Assistant's own OTBR app.
  # The by-id path is what udev actually created (-> ttyACM0); never a bare
  # /dev/ttyACM0, that number moves. An nRF52840 dongle is the cheap alternative:
  # flash ot-rcp, then baudrate = 1000000; flowControl = false;
  radio = {
    device = "/dev/serial/by-id/usb-Nabu_Casa_ZBT-2_94A990D05CCC-if00";
    baudrate = 460800;
    flowControl = true;
  };

  # The host path is the stable by-id symlink; inside the container it is always
  # mounted at a fixed path so the RCP URL never depends on USB enumeration.
  radioDeviceInContainer = "/dev/ttyACM0";
  radioUrl =
    "spinel+hdlc+uart://${radioDeviceInContainer}?uart-baudrate=${toString radio.baudrate}"
    + lib.optionalString radio.flowControl "&uart-flow-control";

  haStateDir = "${vars.serviceConfigRoot}/homeassistant";
  matterStateDir = "${vars.serviceConfigRoot}/matter-server";
  otbrStateDir = "${vars.serviceConfigRoot}/otbr";
in
{
  # Thread traffic is routed between the Thread mesh and the LAN by OTBR, and
  # podman refuses to set net.* sysctls for a container that shares the host's
  # network namespace — so they are host settings. accept_ra=2 keeps the host's
  # own SLAAC address working once IPv6 forwarding is on.
  boot.kernel.sysctl = lib.optionalAttrs otbrEnabled {
    "net.ipv6.conf.all.disable_ipv6" = 0;
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.accept_ra" = 2;
  };

  # OTBR builds its own ip6tables chains backed by ipsets at start, and creates
  # the wpan0 Thread interface through /dev/net/tun. A container cannot modprobe,
  # so the host loads what that needs.
  boot.kernelModules = lib.optionals otbrEnabled [
    "ip6table_filter"
    "ip_set"
    "ip_set_hash_net"
    "xt_set"
    "tun"
  ];

  # lsusb, for identifying the radio on the USB bus. The ZBT-2 should appear as
  # 303a:831a or 303a:4001; 303a:1001 ("USB JTAG/serial debug unit") means its
  # ESP32 bridge fell back to ROM mode and a power cycle is needed.
  #
  # Flashing the ZBT-2 requires `nixpkgs#python3Packages.universal-silabs-flasher`
  # can use nix shell if/when we need it:
  #   nix shell nixpkgs#python3Packages.universal-silabs-flasher
  #   universal-silabs-flasher --device <by-id path> probe
  environment.systemPackages = [ pkgs.usbutils ];

  networking.firewall = {
    # 8123 — Home Assistant, direct on the LAN (independent of traefik).
    allowedTCPPorts = [ 8123 ];
    allowedUDPPorts = [
      5353 # mDNS: Matter operational discovery and HA device discovery
      5540 # Matter commissioning/operational (CHIP)
      1982 # SSDP used by the Yeelight LAN integration
    ] ++ lib.optionals otbrEnabled [
      61631 # Thread backbone router
    ];
  };

  homelab.services.homeassistant = {
    image = homeassistantImage;
    # Host networking: mDNS/SSDP discovery and Matter's link-local IPv6 traffic
    # do not survive podman's bridge. Nothing is published — the container binds
    # the host directly, so HA stays reachable on the LAN with traefik down.
    subdomain = "ha";
    # Required even on host networking: traefik's docker provider resolves a
    # host-mode container via host.containers.internal, but still errors with
    # "port is missing" if no port label is emitted, and drops the whole service.
    port = 8123;
    dirs = [ haStateDir ];
    volumes = [
      "${haStateDir}:/config"
      "/etc/localtime:/etc/localtime:ro"
    ];
    # The official image runs as root and ignores PUID/PGID.
    user = null;
    extraPodmanArgs = [ "--network=host" ];
    homepage = {
      group = "Services";
      name = "Home Assistant";
      icon = "home-assistant.svg";
      description = "Home automation";
      widget = {
        type = "homeassistant";
        url = "https://ha.${vars.domainName}";
      };
    };
  };

  # This container runs unprivileged as uid 1000 (the python server ran as root),
  # so its state dir cannot use the share identity the homelab module hands out —
  # rootful podman maps the container uid straight through to the host.
  systemd.tmpfiles.rules = [
    "d ${matterStateDir} 0750 1000 1000 - -"
  ];

  # Matter controller
  # A sidecar, not a Service: no subdomain, no dashboard entry. Configured by
  # environment rather than cmd, which is this image's documented interface.
  homelab.services.matter-server = {
    image = matterServerImage;
    # dirs is deliberately unset — see the tmpfiles rule above.
    volumes = [
      "${matterStateDir}:/data"
    ];
    # image doesn't consume PUID/PGID
    user = null;
    env = {
      STORAGE_PATH = "/data";
      # Binds the websocket API and the web dashboard to loopback only. Home
      # Assistant shares the host netns so it still reaches ws://localhost:5580/ws,
      # and nothing needs opening in the firewall. The dashboard is then reachable
      # over an ssh tunnel only, which is the intent.
      LISTEN_ADDRESS = "127.0.0.1";
      # Matter traffic and mDNS, unaffected by LISTEN_ADDRESS.
      PRIMARY_INTERFACE = lanInterface;
    };
    extraPodmanArgs = [
      # required for mDNS and for Matter's link-local IPv6 traffic
      "--network=host"
    ];
    # No cmd: STORAGE_PATH already defaults to /data and the image's own entrypoint
    # is left intact. Bluetooth commissioning is off (it would need
    # BLUETOOTH_ADAPTER plus NOBLE_BINDINGS=dbus and a /run/dbus mount);
    # commissioning happens from the phone app.
  };

  # Thread border router
  # Gated on `otbrEnabled` above. HA's otbr integration talks to the REST API on
  # localhost:8081.
  homelab.services.otbr = {
    enable = otbrEnabled;
    image = otbrImage;
    dirs = [ otbrStateDir ];
    volumes = [
      "${otbrStateDir}:/data"
    ];
    # image doesn't consume PUID/PGID
    user = null;
    env = {
      OT_RCP_DEVICE = radioUrl;
      OT_INFRA_IF = lanInterface;
      OT_THREAD_IF = "wpan0";
      # The OTBR web GUI binds :80, which traefik owns, and HA does not need it
      # (the integration only uses the REST API). In some builds this is a
      # build-time option, so after enabling OTBR check `ss -ltnp | grep ':80 '`;
      # if OTBR took it, rebuild the image without the web GUI.
      WEB_GUI = "0";
    };
    extraPodmanArgs = [
      "--network=host"
      # NET_ADMIN covers the wpan0 interface, routing and firewall rules OTBR
      # sets up; IPC_LOCK matches HA's own OTBR app. Full --privileged is not
      # required.
      "--cap-add=NET_ADMIN"
      "--cap-add=IPC_LOCK"
      # stable by-id path on the host, fixed path inside the container
      "--device=${radio.device}:${radioDeviceInContainer}"
      "--device=/dev/net/tun"
    ];
  };

  # Ordering only, not a hard dependency: Home Assistant should come up after its
  # controllers when they are around, but must still start (and restart) cleanly
  # when one of them is broken.
  systemd.services.podman-homeassistant = {
    after = [ "podman-matter-server.service" ]
      ++ lib.optional otbrEnabled "podman-otbr.service";
    wants = [ "podman-matter-server.service" ]
      ++ lib.optional otbrEnabled "podman-otbr.service";
  };
}
