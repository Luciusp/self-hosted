include {
  path  = find_in_parent_folders("common.hcl")
  expose = true
}

terraform {
  source = find_in_parent_folders("modules/submodules/cloudflare")
}

inputs = {
  registar_api_token =
  primary_domain = include.locals.proxmox_endpoint
}
