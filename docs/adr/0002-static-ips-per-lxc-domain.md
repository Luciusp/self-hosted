# Static IPs per LXC Domain

Each LXC Domain is assigned a fixed IP address in its Terragrunt config rather than relying on DHCP or DHCP reservations.

Three cross-domain dependencies need stable addressing: `services` mounting `store` over NFS, Caddy on the external RPi4 reverse-proxying to services, and apps connecting to Postgres in `store`. Static IPs keep a single source of truth in Terraform and survive reboots, avoiding broken NFS mounts and Caddy upstreams that DHCP lease churn would cause.
