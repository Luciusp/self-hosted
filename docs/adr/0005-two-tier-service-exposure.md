# Two-tier service exposure: public via Cloudflare, private via Pi-hole + Tailscale

Every service is either a Public Service or a Private Service. All north-south
traffic terminates at Caddy on the external RPi4 (`192.168.0.216`), which routes
by hostname to a service's static IP and port.

- **Public**: `<service>.<domain>`, published to Cloudflare as a proxied
  (orange-cloud) record. Flow: Cloudflare proxy → Caddy → static IP:port.
- **Private**: `<service>.lan.<domain>`, registered only in Pi-hole via
  the `pihole` Terraform provider, never in Cloudflare. Reachable on the LAN or
  over Tailscale. Flow: Pi-hole DNS → Caddy → static IP:port. Uses the
  same domain so Caddy can issue automatic HTTPS.

Tailscale (integrated with Authentik) is the VPN for private access, replacing
the previously-planned Wireguard. Using the real domain for private records
keeps one ACME/HTTPS story for both tiers; keeping private records out of
Cloudflare avoids exposing internal hostnames publicly.
