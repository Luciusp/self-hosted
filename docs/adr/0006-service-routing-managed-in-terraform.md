# Per-service DNS and Caddy routing managed in Terraform

A per-service module (evolved from the existing `hosted-service` module)
registers a service's full north-south path as IaC: the DNS record (Cloudflare
provider for Public Services, `pihole` provider for Private Services) and the
Caddy route (Caddy Terraform provider, which drives Caddy's admin API). Routing
is keyed off the service's static IP and port.

We deliberately avoided `caddy-docker-proxy` (the obvious homelab default).
Because Caddy runs on the external RPi4 while services run on separate LXC
Docker hosts, label-based discovery would require exposing each host's Docker
socket over the network — an unacceptable attack surface across six hosts.
Managing routes in Terraform keeps one consistent IaC story with the DNS
records and avoids socket exposure.
