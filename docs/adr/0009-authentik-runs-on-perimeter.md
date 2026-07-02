# Perimeter: always-on RPi4 outside IaC scope

The RPi4 at `192.168.0.216` is designated the **Perimeter** — a permanently running host that owns the entire north-south path and is managed manually, not via Terraform/Terragrunt.

Stacks running on the Perimeter: Caddy (reverse proxy), Pi-hole (Private Service DNS), Cloudflare DDNS client, and Authentik (identity provider).

The Perimeter is intentionally excluded from IaC for two reasons. First, its availability must be unconditional — it must stay up through Proxmox reboots, Terraform runs, and LXC lifecycle events, none of which should be able to take down DNS, routing, or authentication. Second, it is a single physical device with no reprovisioning story; applying IaC to it would add process overhead with no benefit.

Placing Authentik on the Perimeter rather than an LXC Domain follows from the same principle: the IdP must be available whenever Caddy is available, since authentication and routing share the same availability requirement. Keeping all north-south concerns on one device also simplifies the dependency graph — there is no cross-host coupling between the proxy and the IdP.
