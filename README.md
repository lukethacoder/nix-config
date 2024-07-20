# NixOS

> NOTE: this NixOS config is not currently working and is a work in progress. Take anything in this repo with a grain of salt.

## Machines

### Opslag

Main Home Server machine. Will eventually host some sort of RAID/mergerFS/SnapRaid setup as well as a few home server services like Jellyfin, Navidrome, PiHole etc.

## Setup

```
cd ~/Github
git clone https://github.com/lukethacoder/.dotfiles
cd .dotfiles/nixos

nixos-rebuild switch 
```

```
DISK='/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_500GB_S466NX0K701415F'

curl https://raw.githubusercontent.com/lukethacoder/nix-config/main/disko/default.nix \
    -o /tmp/disko.nix
sed -i "s|to-be-filled-during-installation|$DISK|" /tmp/disko.nix
nix --experimental-features "nix-command flakes" run github:nix-community/disko \
    -- --mode disko /tmp/disko.nix
```

## TODO

- [ ] Setup SSH
- [ ] Disko Configuration
- [ ] Test Disk recovery
- [ ] Containers (Jellyfin, Navidrome, etc.)
- [ ] Modules
    - [ ] DuckDNS
    - [ ] Tailscale
    - [ ] WireGuard
    - [ ] Pi-Hole
