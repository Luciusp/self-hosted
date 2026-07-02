include {
  path = find_in_parent_folders("common.hcl")
  expose = true
}

terraform {
  source = find_in_parent_folders("modules/docker-service")
}

inputs = {
    domain = "${include.locals.primary_domain_name}.com"
    subdomain = "hedgedoc"
    service_name = "hedgedoc"
    service_privacy = "public"

    ip_target = include.locals.caddy_ip
    registrar_api_token = include.locals.cloudflare_api_token
    pihole_host = "http://${include.locals.pihole_host}"
    pihole_password = include.locals.pihole_password
}
