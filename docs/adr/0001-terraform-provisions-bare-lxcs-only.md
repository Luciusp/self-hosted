# Terraform provisions bare LXCs only

Terraform/Terragrunt is responsible for provisioning bare LXC Domains
(CPU/memory/disk/network/static IP) and attaching a cloud-init hook that turns
the Debian Golden Template into a Docker host. It does **not** deploy or manage
Docker Compose stacks or container lifecycle — that happens in a separate layer.

We chose this boundary because Terraform manages declarative infrastructure
well but handles container lifecycle poorly (drift, no `docker compose pull`
equivalent). Keeping the boundary at "bare Docker host" preserves the
`docker compose pull && up` workflow and gives a clean Terragrunt dependency
graph where service deployments can depend on the LXC that hosts them.
