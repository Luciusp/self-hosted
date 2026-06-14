include {
  path = find_in_parent_folders("common.hcl")
}

terraform {
  source = find_in_parent_folders("modules/hosted-service")
}

inputs = {
    service_name = "hedgedoc"
}
