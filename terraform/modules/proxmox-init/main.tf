resource "proxmox_virtual_environment_user" "terraform" {
  user_id = "terraform@pve"
  acl {
    path      = "/" # permissions on everything
    propagate = true
    role_id   = "PVEAdmin"
  }
  comment = "Managed by Terraform"
}

resource "proxmox_virtual_environment_user_token" "terraform" {
  user_id               = proxmox_virtual_environment_user.terraform.user_id
  token_name            = "terraform-token"
  privileges_separation = false
  comment               = "Terraform automation token"
}

# Create the secret in that project
resource "bitwarden_secret" "secrets" {
  key        = "proxmox_terraform_token"
  value      = "${proxmox_virtual_environment_user_token.terraform.user_id}!${proxmox_virtual_environment_user_token.terraform.token_name}=${proxmox_virtual_environment_user_token.terraform.value}"
  note       = "Terraform automation token for Proxmox"
  project_id = var.bitwarden_project_id
}
