locals {
    secrets = jsondecode(read_tfvars_file("secrets.tfvars"))
}

include {
    path = find_in_parent_folders("common.hcl")
}

terraform {
    source = find_in_parent_folders("modules/bitwarden")
}

inputs = merge(local.secrets, {})
