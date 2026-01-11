locals {
  secrets_map = jsondecode(run_cmd("--terragrunt-quiet", "bash", find_in_parent_folders("scripts/get-secrets.sh"), "proxmox_root_pw"))
}

include {
  path = find_in_parent_folders("common.hcl")
}

terraform {
  source = find_in_parent_folders("modules/proxmox-init")
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.92.0"
    }
    bitwarden = {
      source  = "maxlaverse/bitwarden"
      version = ">= 0.13.6"
    }
  }
}

provider "proxmox" {
  endpoint = "https://192.168.0.2:8006/"
  username = "root@pam"
  password = "${local.secrets_map.proxmox_root_pw}"
  insecure = true
}

provider "bitwarden" {
  experimental {
    embedded_client = true
  }
}
EOF
}

inputs = {
  bitwarden_project_id = "45fa2894-789a-431e-afb5-b2de01285f45"
}
