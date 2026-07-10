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
    stack_config = jsondecode(
        run_cmd(
            "--terragrunt-quiet",
            "bws secret list | jq '.[] | select(.key == \"perimeter/config\").value' | jq fromjson"
        )
    )
    primary_dns  = local.stack_config.primary_dns
    perimeter_ip = local.stack_config.perimeter_ip
    proxmox_ip   = local.stack_config.proxmox_ip
    proxmox_port = local.stack_config.proxmox_port
    admin_email  = local.stack_config.admin_email
}
