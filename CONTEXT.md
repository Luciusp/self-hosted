# Self-Hosted Infrastructure

A single Proxmox node hosting services in Docker, where each Docker host is a
purpose-grouped LXC container provisioned by Terraform/Terragrunt.

## Language

### Provisioning

**LXC Domain**:
A single LXC container that acts as a Docker host for a group of functionally
related services. The unit of provisioning. There are five: `ai`, `forge`,
`store`, `services`, `games`.
_Avoid_: VM, host, node (a "node" is the Proxmox machine itself)

**Bare LXC**:
An LXC as Terraform leaves it — provisioned with CPU/memory/disk/network and a
cloud-init hook, but with service deployment handled outside Terraform.

**Golden Template**:
The Debian LXC template (with Docker pre-installed or installed via cloud-init)
that every LXC Domain is created from.

**Stack**:
A Docker Compose definition for a group of containers, version-controlled in
external Git and deployed onto an LXC Domain by Komodo.

**Periphery Agent**:
The Komodo agent running on each LXC Domain that executes `compose pull && up`
on behalf of the Komodo core in `forge`.

### Data layer

**Store**:
The centralized data-layer LXC Domain. Owns persistent data (downloads,
databases, synced files) and exposes it over the network so no other domain
holds the source of truth.
_Avoid_: NAS, fileserver

**Library**:
The collection of media/document files in `store` that internal services
(Audiobookshelf, Paperless) read over NFS.

### Service exposure

**Public Service**:
A service reachable from anywhere at `<service>.<domain>`. Its DNS
record is published to Cloudflare as a proxied (orange-cloud) record; traffic
flows Cloudflare proxy → Caddy → the service's static IP and port.

**Private Service**:
A service reachable only on the LAN or over Tailscale, at
`<service>.lan.<domain>`. Its record lives only in Pi-hole (never
Cloudflare); traffic flows Pi-hole DNS → Caddy → the service's static IP and
port. Still uses the same domain so Caddy can issue automatic
HTTPS certificates.

**Perimeter**:
The always-on RPi4 (`192.168.0.216`) that sits outside the Proxmox stack and
owns the entire north-south path: Caddy (reverse proxy), Pi-hole (Private
Service DNS), Cloudflare DDNS client, Authentik (identity provider), and
Tailscale (VPN). Its uptime is independent of the Proxmox node. Managed
manually — not provisioned via Terraform/IaC.

**Caddy**:
The single reverse proxy for all north-south traffic, running on the Perimeter.
Terminates HTTPS and routes both public and private hostnames to service
static IPs.

**Native SSO**:
Authentication via a service's first-class Authentik integration (OIDC/SAML),
configured per-service. The deliberate alternative to proxy-level forward-auth,
chosen for true end-to-end SSO.

## Access methods

**NFS Mount**:
Machine-to-machine access. How internal services in other domains read the
`store` Library as a local filesystem. Declared per-container as a Docker
volume (local driver, NFS options) so the LXC Domain stays a plain Docker host.

**On-demand Access**:
Human-to-machine file access via CopyParty (browser/WebDAV) — used to grab a
one-off file (e.g. a finished torrent) onto any device.

**Live Sync**:
Always-identical-everywhere file replication via Syncthing — used for Obsidian
vaults, dotfiles, and emulator saves across devices.
