# Homelab (opslag)

The NixOS configuration for the `opslag` home server: a set of self-hosted
services running as podman containers over a mergerfs storage array, reverse-proxied
by traefik and surfaced on a homepage dashboard.

## Language

**Service**:
A self-hosted application running on opslag, reachable at a subdomain of the
homelab domain. One Service may be realised by several containers.
_Avoid_: app, container (a container is a runtime artifact of a Service, not the Service itself)

**Service declaration**:
The single per-Service statement of everything the homelab needs to know about
it — what to run, where it's reachable, what it stores, how it appears on the
dashboard. Everything else about running a Service is derived from its declaration.
_Avoid_: container config, service module

**Sidecar**:
A supporting container belonging to a Service that is not itself a Service —
it has no subdomain and no dashboard presence (e.g. a Service's database or cache).
_Avoid_: helper container

**Observer**:
A Service that watches other Services rather than serving its own content — the
dashboard (homepage) and metrics collector (prometheus). Observers learn about
Services from their declarations, never the other way around.
_Avoid_: integration, widget config (a widget is what an Observer renders, not the relationship)

**Share identity**:
The one uid/gid pair that owns shared media and service state across the Samba
shares, the Array, and containers. There is exactly one; a Service that runs as
anything else is the exception and says so.
_Avoid_: PUID/PGID (those are how images consume it, not the concept)

**Array**:
The mergerfs pool of data disks (plus snapraid parity) where media lives.
Distinct from per-Service state, which lives on the persist volume.
_Avoid_: NAS, storage
