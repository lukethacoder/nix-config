# Home Assistant, Matter and Thread

Three containers, all on the host network:

| Service         | Role                       | Endpoint                          |
| --------------- | -------------------------- | --------------------------------- |
| `homeassistant` | the hub                    | `http://<opslag>:8123`            |
| `matter-server` | **Matter controller**      | `ws://localhost:5580/ws`          |
| `otbr`          | **Thread border router**   | `http://localhost:8085` (REST)    |

`matter-server` and `otbr` are separate things and both are required for a
Matter-over-Thread device. Thread is the radio mesh; Matter is the application
layer that runs over it. A working border router with no Matter controller pairs
nothing, and vice versa.

The Home Assistant Connect ZBT-2 is **dedicated to Thread**. The radio runs one
protocol at a time, so this host cannot also do Zigbee. A Zigbee device needs a
second radio.

## First-time bring-up

Do these in order. Each step assumes the previous one is verified.

1. **Home Assistant** — `http://<opslag>:8123` directly, and onboard. Before
   touching traefik.

2. **Matter integration** — point it at `ws://localhost:5580/ws`. The same port
   serves a dashboard (node detail, Thread mesh view) on `http://localhost:5580/`,
   bound to loopback, so reach it over an ssh tunnel.

3. **Thread network** — OTBR forms nothing on its own. See below.

4. **OpenThread Border Router integration** — point it at
   `http://localhost:8085`. The HA Thread panel should then report a preferred
   network.

5. **Sync Thread credentials to your phone**, from the HA Thread panel. This is
   the step people miss. A bulb joins whatever network your *phone* hands it —
   from Play Services on Android, or the Apple keychain on iOS — not from HA
   directly. Without this, commissioning fails immediately after the QR scan.

6. **Commission devices** from the HA companion app, on the same LAN as opslag.
   Matter commissioning is link-local multicast and does not route across VLANs.

7. **Reverse proxy last.** Check both the traefik route and the websocket — the
   HA UI goes blank on a broken WS while plain HTTP still looks fine.

## Forming the Thread network

`otbr` starts in state `disabled` with the compiled-in placeholder network name
`OpenThread` and ExtPanId `dead00beef00cafe`. `wpan0` stays `DOWN` until a
dataset is committed. This is a manual step:

```bash
sudo podman exec otbr ot-ctl dataset init new
sudo podman exec otbr ot-ctl dataset commit active
sudo podman exec otbr ot-ctl ifconfig up
sudo podman exec otbr ot-ctl thread start
```

Wait ~10s, then confirm `leader` and a *randomised* network name:

```bash
curl -s http://localhost:8085/node | jq '{state, networkName, extPanId}'
ip -br addr show wpan0
```

**Back up the dataset immediately.** It contains the network key; losing it
means every commissioned device is stranded:

```bash
sudo podman exec otbr ot-ctl dataset active -x
```

> **Never commit that hex string.** Unlike `/node`, the active dataset carries
> the Thread **network key** and **PSKc** — anyone holding it can join the mesh
> and talk to every device on it. It belongs in a password manager or in
> nix-secrets (sops-encrypted), never in this repo in plaintext.

To restore that dataset on a rebuilt host, substitute the saved hex for
`dataset init new`:

```bash
sudo podman exec otbr ot-ctl dataset set active <hex>
sudo podman exec otbr ot-ctl ifconfig up
sudo podman exec otbr ot-ctl thread start
```

A host restoring the same dataset comes up on the same Thread network and
existing devices rejoin on their own.

> This could be automated — store the dataset hex in sops and apply it with a
> oneshot unit after `podman-otbr.service`. Deliberately not done: it is one
> command on the rare occasions it is needed, and it keeps the network key out
> of another moving part.

### Does the dataset survive a restart?

**Unverified.** `podman-otbr.service` runs with `--rm`, so every restart is a
fresh container. Whether `otbr-agent` persists its dataset under the `/data`
mount or under a compiled-in path inside the container has not been confirmed.
Test it:

```bash
sudo systemctl restart podman-otbr && sleep 15
curl -s http://localhost:8085/node | jq '{state, networkName}'
```

`leader` with the same network name means persistence works. Back to
`disabled`/`OpenThread` means the storage path needs fixing in `default.nix`,
and the network must be re-applied after every restart until it is.

## Commissioning a Matter device

Bluetooth commissioning is **disabled** on `matter-server` (it would need
`BLUETOOTH_ADAPTER`, `NOBLE_BINDINGS=dbus` and a `/run/dbus` mount). The phone's
BLE radio is the only path to a new device.

- Scan the QR inside the HA companion app: **Settings → Devices & Services →
  Add device → Matter**. Scanning it with a camera or generic barcode app does
  nothing.
- A Matter device carries the Matter logo and an **11-digit numeric setup code**
  next to the QR. No logo and no 11-digit code means it is not a Matter device.
- Factory-new devices are in commissioning mode on first power-up for **~15
  minutes**. After that, or after a half-finished attempt, they ignore you until
  factory reset (power-cycle toggle, count per the manufacturer's leaflet).
- Phone needs Bluetooth on, and on Android the HA app needs Bluetooth and
  location permissions.

Watch the controller during an attempt:

```bash
sudo podman logs -f matter-server
```

## What is not declarative

| Layer                          | Reproducible from nix? |
| ------------------------------ | ---------------------- |
| Containers, radio, ports, caps | yes                    |
| Thread network / dataset       | no — manual, see above |
| Matter fabric                  | no                     |
| HA integration config entries  | no                     |

The Matter fabric is created by physical BLE commissioning, once per device. HA
stores integration config entries in `.storage`, not YAML. Neither has a
declarative representation.

Both live on the persist volume, so recreating a container costs nothing:

- `services/matter-server` — the Matter fabric
- `services/otbr` — Thread credentials
- `services/homeassistant` — HA's own config, including `.storage`

Losing `matter-server` state means factory-resetting and re-commissioning every
device. **Restore from backup rather than rebuild.**

Replacing the radio itself is only a new `radio.device` path.

Note that HA rewrites its own `configuration.yaml`, so it is not templated from
nix. Anything needed there (such as `trusted_proxies` for the reverse proxy) is
edited in place.

## Troubleshooting

Start here. Work down — each check assumes the ones above it pass.

```bash
lsusb | grep -iE '303a|nabu'          # radio present
ip -br addr show wpan0                 # thread interface
curl -s http://localhost:8085/node     # otbr REST + thread state
sudo journalctl CONTAINER_NAME=otbr -n 60 --no-pager
```

`podman logs otbr` returns nothing useful — the container runs with `--rm` and
is gone before you can read it. Use `journalctl CONTAINER_NAME=otbr`.

### `wpan0` does not exist

OTBR is crashlooping. Check `systemctl status podman-otbr` for the restart
counter, and read the journal.

### `wpan0` exists but is DOWN

Expected when no dataset is committed. The agent logs `cannot get LeaderData
while detached` and `Host netif is down`, and `/node` reports `state: disabled`.
Form the network.

### `socket(SOCK_CLOEXEC): Operation not permitted`

```
mldListenerInit() at netif.cpp:2137: Failure
socket(SOCK_CLOEXEC): Operation not permitted
```

Missing `CAP_NET_RAW`. `otbr-agent` brings up `wpan0` then opens a raw ICMPv6
socket for MLD. **Podman does not grant `NET_RAW` by default; Docker does** —
which is why no OTBR-in-Docker guide mentions it. Fixed in `default.nix`; if it
reappears, that cap was dropped.

The `ip6tables ... Can't open socket to ipset` warnings have the same cause and
clear up with it.

### `REST server failed to start on 127.0.0.1:<port>`

Port collision. OTBR runs with `--network=host`, so it competes with every
published host port. Upstream defaults to 8081, which `containers/immich` already
publishes for metrics — hence `restPort = 8085` here. If it moves again, update
the OTBR integration URL in HA to match.

```bash
ss -ltnp | grep ':8085 '
```

### Is the ZBT-2 on the right firmware?

The dongle must run OpenThread RCP firmware, not Zigbee. The cheap check is the
journal — a working RCP announces itself:

```
[INFO]-APP-----: Radio Co-processor version: SL-OPENTHREAD/2.7.2.0_GitHub-fb0446f53; EFR32
```

Zigbee firmware cannot produce that line; you would see spinel handshake failures
instead. **Do not run `universal-silabs-flasher` while `podman-otbr` is up** — it
holds the serial port. Stop the unit first:

```bash
sudo systemctl stop podman-otbr
sudo nix shell nixpkgs#python3Packages.universal-silabs-flasher -c \
  universal-silabs-flasher --device /dev/serial/by-id/usb-Nabu_Casa_ZBT-2_*-if00 probe
sudo systemctl start podman-otbr
```

`PermissionError` from the flasher is just a missing `dialout` group — use sudo.

### `303a:1001` on the USB bus

The ESP32 bridge fell back to ROM mode ("USB JTAG/serial debug unit"). Physically
power-cycle the dongle. Healthy IDs are `303a:831a` or `303a:4001`.

### A bulb will not pair

Work outwards from the host:

1. Is there a Thread network at all? `/node` should say `leader`, `wpan0` UP.
2. Does the HA Thread panel show it as the **preferred network**?
3. Have Thread credentials been synced to the phone?
4. Is the phone on the same LAN as opslag — not a guest SSID or separate IoT
   VLAN? Commissioning does not route across VLANs.
5. Is the device still inside its ~15 minute commissioning window?

Steps 2 and 3 are the usual culprits on a self-hosted border router.

### What a healthy node looks like

Values below are redacted — this repo is public, and `extAddress`, `baId`,
`extPanId` and the mesh-local prefix in `rlocAddress` are stable identifiers for
a specific radio and network. No credentials appear here (`/node` never returns
the network key or PSKc), but there is no reason to publish the identifiers.

What matters is the shape: `state` is `leader`, and `networkName`/`extPanId` are
randomised rather than the placeholder `OpenThread`/`dead00beef00cafe`.

```json
{
  "baId": "<32 hex>",
  "baState": "",
  "state": "leader",
  "routerCount": 1,
  "rlocAddress": "<mesh-local ULA>:0:ff:fe00:1800",
  "extAddress": "<16 hex>",
  "networkName": "OpenThread-xxxx",
  "rloc16": "0x1800",
  "routerId": 6,
  "leaderData": {
    "partitionId": 0,
    "weighting": 65,
    "dataVersion": 90,
    "stableDataVersion": 194,
    "leaderRouterId": 6
  },
  "extPanId": "<16 hex>"
}
```

> See 1password for current setup
