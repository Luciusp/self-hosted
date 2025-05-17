resource "bitwarden_project" "home_infrastructure" {
  name = "home-infrastructure2"
}

resource "bitwarden_secret" "secrets" {
  for_each   = var.secrets_map
  key        = each.key
  value      = each.value
  project_id = bitwarden_project.home_infrastructure.id
  note       = "Terraform managed secret"
}

output "secrets" {
  sensitive = true
  value     = bitwarden_secret.secrets
}
