locals {
  secrets_map = jsondecode(run_cmd("--terragrunt-quiet", "bash", find_in_parent_folders("scripts/get-secrets.sh"), "proxmox_root_pw"))
}

include {
  path = find_in_parent_folders("common.hcl")
}

terraform {
  source = find_in_parent_folders("modules/proxmox/datacenter-init")
}

inputs = {
  bitwarden_project_id = "45fa2894-789a-431e-afb5-b2de01285f45"
  pm_url               = "https://192.168.0.2:8006/"
  pm_root_usr          = "root@pam"
  pm_root_pw           = local.secrets_map.proxmox_root_pw
}
