terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.109.0"
    }
    bitwarden-secrets = {
      source = "registry.terraform.io/bitwarden/bitwarden-secrets"
    }
    null = {
      source = "hashicorp/null"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token

  ssh {
    username = var.proxmox_terraform_username
    password = var.proxmox_terraform_user_password
  }

}

provider "bitwarden-secrets" {
  api_url         = "https://api.bitwarden.com"
  identity_url    = "https://identity.bitwarden.com"
  access_token    = var.bitwarden_access_token
  organization_id = var.bitwarden_organization_id
}
