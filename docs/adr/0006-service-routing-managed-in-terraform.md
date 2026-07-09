# Per-service DNS and Caddy routing managed in Terraform

A per-service module (evolved from the existing `hosted-service` module) registers a service's full north-south path as IaC: the DNS record using the Cloudflare provider for Public Services, `pihole` provider for Private Services. Caddy definitions will be managed via git.

We deliberately avoided `caddy-docker-proxy` (the obvious homelab default). Because Caddy runs on the Perimeter while services run on separate LXC Docker hosts, label-based discovery would require exposing each host's Docker socket over the network — an unacceptable attack surface across five hosts. Managing routes in Terraform keeps one consistent IaC story with the DNS records and avoids socket exposure.
