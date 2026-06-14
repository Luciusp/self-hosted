remote_state {
    backend = "gcs"
    generate = {
        path = "backend.tf"
        if_exists = "overwrite_terragrunt"
    }
    config = {
        prefix = "${path_relative_to_include()}"
        bucket = "terraform-state-e9405433-c350-4e9f-b5f3-edb2c2323fd4"
    }
}

locals {
    secrets_map = jsondecode(
        run_cmd(
            "--terragrunt-quiet",
            "bash",
            find_in_parent_folders("scripts/get-secrets.sh"),
            "proxmox_terraform_token",
            "bitwarden_terraform_access_token",
            "bitwarden_organization_id",
            "bitwarden_project_id_lumen",
            "proxmox_endpoint",
            "proxmox_terraform_username",
            "proxmox_terraform_user_password"
        )
    )
    proxmox_endpoint = local.secrets_map.proxmox_endpoint
    proxmox_api_token = local.secrets_map.proxmox_terraform_token
    proxmox_terraform_username = local.secrets_map.proxmox_terraform_username
    proxmox_terraform_user_password = local.secrets_map.proxmox_terraform_user_password
    bitwarden_access_token = local.secrets_map.bitwarden_terraform_access_token
    bitwarden_organization_id = local.secrets_map.bitwarden_organization_id
    bitwarden_project_id_lumen = local.secrets_map.bitwarden_project_id_lumen

    default_gateway = "192.168.0.1"
}
