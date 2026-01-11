resource "proxmox_virtual_environment_user" "terraform" {
  user_id = "terraform@pve"
  acl {
    path      = "/" # permissions on everything
    propagate = true
    role_id   = "Administrator"
  }
  comment = "Managed by Terraform"
}

resource "proxmox_virtual_environment_user_token" "terraform" {
  user_id               = proxmox_virtual_environment_user.terraform.user_id
  token_name            = "terraform-token"
  privileges_separation = false
  comment               = "Terraform automation token"
}

# Store the Terraform token in Bitwarden Secrets
resource "bitwarden_secret" "terraform_token" {
  key        = "proxmox_terraform_token"
  value      = proxmox_virtual_environment_user_token.terraform.value
  note       = "Terraform automation token for Proxmox"
  project_id = var.bitwarden_project_id
}
