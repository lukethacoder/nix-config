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

## TODO

- [ ] Disko Configuration
- [ ] Test Disk recovery
- [ ] Setup SSH
- [ ] Containers (Jellyfin, Navidrome, etc.)