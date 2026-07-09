# Services must not be reachable via direct IP

All services are accessible only through their assigned DNS hostname via Caddy. Direct access by IP address and port is blocked at the network layer, so Caddy is the sole entry point for all HTTP traffic. This ensures Caddy's routing, TLS termination, and Authentik forward-auth cannot be bypassed.

Two isolation mechanisms apply depending on where the service runs:

- **Co-located on the Perimeter (same Docker host as Caddy)**: The service joins an internal Docker network shared with Caddy and publishes no host ports. Caddy reaches it by container name. No route exists from the LAN to the service's web interface. DNS-facing ports (e.g. Pi-hole on 53) are the only exception.
- **On a Proxmox LXC**: The LXC's Proxmox firewall is configured (via the `docker-lxc` Terraform module) to accept inbound traffic only from the Perimeter IP. All other LAN sources are dropped. Caddy proxies to the LXC's static IP over the LAN, but no other host can reach the service port directly.

Tailscale provides remote network access but is not the sole access control. A device on Tailscale can reach the LAN but still must go through Caddy for per-service routing and authentication. Tailscale ACLs are not used as a substitute for per-service Authentik policies.

This is a target state. The Proxmox firewall integration in the `docker-lxc` module is not yet implemented; until it is, LXC-hosted services remain reachable by direct IP on the LAN. The Docker network isolation for co-located services is implemented as part of the perimeter stack.
