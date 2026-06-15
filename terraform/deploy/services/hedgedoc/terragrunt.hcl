include {
  path = find_in_parent_folders("common.hcl")
  expose = true
}

terraform {
  source = find_in_parent_folders("modules/docker-service")
}

inputs = {
    service_name = "hedgedoc"
    service_privacy = "public"
    registrar_api_token = include.locals.cloudflare_api_token
    domain = "hollowforge.com"
    subdomain = "hedgedoc"
}
