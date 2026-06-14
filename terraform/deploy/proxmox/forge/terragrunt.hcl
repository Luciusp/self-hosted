include {
  path  = find_in_parent_folders("common.hcl")
  expose = true
}

terraform {
  source = find_in_parent_folders("modules/docker-lxc")
}

inputs = {
  lxc_name = "forge"
  destination_node_name = "kamino"
  static_ip = "192.168.0.11/24"
  os_template = "debian-13-standard_13.1-2_amd64.tar.zst"
  os_type = "debian"
  memory_mb = 2048
  cpu_cores = 2

  proxmox_endpoint = include.locals.proxmox_endpoint
  proxmox_api_token = include.locals.proxmox_api_token
  proxmox_terraform_username = include.locals.proxmox_terraform_username
  proxmox_terraform_user_password = include.locals.proxmox_terraform_user_password
  bitwarden_access_token = include.locals.bitwarden_access_token
  bitwarden_organization_id = include.locals.bitwarden_organization_id
  bitwarden_project_id = include.locals.bitwarden_project_id_lumen
  default_gateway = include.locals.default_gateway
}
