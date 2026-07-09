include {
  path = find_in_parent_folders("common.hcl")
  expose = true
}

terraform {
  source = find_in_parent_folders("modules/dns")
}

inputs = {
    domain = "${include.locals.primary_domain_name}.com"
    subdomain = "kamino"
    service_name = "kamino"
    service_privacy = "private"

    ip_target = include.locals.caddy_ip
    registrar_api_token = include.locals.cloudflare_api_token
    pihole_host = "http://${include.locals.pihole_host}"
    pihole_password = include.locals.pihole_password
}
