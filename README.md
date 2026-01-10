# NixOS

> [!warning]
> this NixOS config is still a work in progress. Take anything in this repo with a grain of salt (for now).

## Machines

### Opslag

| Icon                                                                                                      | Name           | Description                                  | Category      |
| --------------------------------------------------------------------------------------------------------- | -------------- | -------------------------------------------- | ------------- |
| <img src='https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/navidrome.svg' width=32 height=32>  | Navidrome      | Self-hosted music streaming service          | Media         |
| <img src='https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/copyparty.svg' width=32 height=32>  | copyparty      | File server with resumable uploads/downloads | Services      |
| <img src='https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/jellyfin.svg' width=32 height=32>   | Jellyfin       | The Free Software Media System               | Media         |
| <img src='https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/deluge.svg' width=32 height=32>     | Deluge         | Torrent client                               | Downloads     |
| <img src='https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/gluetun.svg' width=32 height=32>    | Gluetun        | VPN client                                   | Services      |
| <img src='https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/grafana.svg' width=32 height=32>    | Grafana        | Platform for data analytics and monitoring   | Observability |
| <img src='https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/prometheus.svg' width=32 height=32> | Prometheus     | Monitoring system & time series database     | Observability |
| <img src='https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/traefik.svg' width=32 height=32>    | Traefik        | Reverse Proxy                                | Services      |
| <img src='https://getsops.io/favicons/android-192x192.png' width=32 height=32>                            | sops           | Secrets Management                           | Tool          |
| <img src='https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/cloudflare.svg' width=32 height=32> | Cloudflare DNS | DNS                                          | Tool          |

### 🚧 Under Construction / Coming Soon

| Icon                                                                                                          | Name           | Description                                     | Category   |
| ------------------------------------------------------------------------------------------------------------- | -------------- | ----------------------------------------------- | ---------- |
| <img src='https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/miniflux-light.svg' width=32 height=32> | Miniflux       | Minimalist and opinionated feed reader          | Services   |
| <img src='https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/immich.svg' width=32 height=32>         | Immich         | Self-hosted photo and video management solution | Media      |
| <img src='https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/home-assistant.svg' width=32 height=32> | Home Assistant | Home automation platform                        | Smart Home |
| <img src='https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/uptime-kuma.svg' width=32 height=32>    | Uptime Kuma    | Service monitoring tool                         | Services   |

### Hoofd (Daily driver laptop)

Will eventually have a laptop configured with NixOS as a daily driver.

Will host a simple config with:

- Zed & VSCodium
- [Helium](https://helium.computer/) (Chromium based browser)
- [Floorp](https://floorp.app/) (Firefox based browser)
- Other DX tools + languages (Node (nvm), Rust, Python, etc.)

## Setup

```bash
mkdir -p /mnt/etc/nixos/

git clone https://github.com/lukethacoder/nix-config /mnt/etc/nixos/
```

> TODO: do we use disko or nah?
>
> Before running, make sure to edit the `disko/` configuration you wish to use.

```bash
# nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko /mnt/etc/nixos/disko/opslag.nix
```

Double check your disk has been correctly partitioned.

<!-- TODO: add GParted screenshot of a "good partition" -->

```bash
# Generate the flake.lock file
sudo nix --experimental-features "nix-command flakes" flake lock

# Check the configuration
nix --experimental-features "nix-command flakes" repl

nix-repl:> :lf .
# added 9 variables

nix-repl:> outputs.nixosConfigurations.opslag.config.fileSystems
# { "/" = { ... }; "/boot" = { ... }; }

nix-repl:> outputs.nixosConfigurations.opslag.config.fileSystems."/"
# { autoFormat = false; autoResize = false; depends = [ ... ]; device = "/dev/disk/by-partlabel/disk-main-root"; encrypted = { ... }; formatOptions = null; fsType = "ext4"; label = null; mountPoint = "/"; neededForBoot = false; noCheck = false; options = [ ... ]; stratis = { ... }; }
```

Install NixOS

```bash
# the '#opslag' is the name of your device you setup in your flake
sudo nixos-install --root /mnt --flake '/mnt/etc/nixos#opslag'
# NOTE: You will be prompted to set the root password at this point.
sudo reboot
```
