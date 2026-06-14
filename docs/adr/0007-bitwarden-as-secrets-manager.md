# Bitwarden as the secrets manager

Bitwarden (via the `bws` Secrets Manager CLI) is the single source of truth for
secrets across the stack. Terragrunt pulls secrets from Bitwarden at plan/apply
time, and Komodo sources Compose Stack secrets from Bitwarden so nothing
sensitive lives in Git.

We standardize on one secrets manager rather than splitting between Terraform
and runtime tooling. Bitwarden was already in use for the vault, keeps secrets
out of version control entirely, and avoids running a separate secrets service.
The lock-in is the `bws` CLI dependency and the requirement that operators
export a `BWS_ACCESS_TOKEN` before running Terragrunt.
