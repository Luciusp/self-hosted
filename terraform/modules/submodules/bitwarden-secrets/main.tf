data "bitwarden-secrets_list_secrets" "secrets" {}

locals {
  # Secrets can only be fetched by their ids, so we need to map their names to ids first
  secret_ids = { for secret_meta in data.bitwarden-secrets_list_secrets.secrets.secrets : secret_meta.key => secret_meta.id }
}

data "bitwarden-secrets_secret" "secret" {
  for_each = toset(var.secrets_to_retrieve)
  id       = local.secret_ids[each.value]
}

output "secrets" {
  sensitive = true
  value     = { for secret_name in var.secrets_to_retrieve : secret_name => data.bitwarden-secrets_secret.secret[secret_name].value }
}
