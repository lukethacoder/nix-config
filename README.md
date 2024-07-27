# NixOS

> NOTE: this NixOS config is not currently working and is a work in progress. Take anything in this repo with a grain of salt (for now).

## Machines

### Opslag

Main Home Server machine. Will eventually host some sort of MergerFS/SnapRaid setup as well as a few services like Jellyfin, Navidrome, PiHole etc.

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
