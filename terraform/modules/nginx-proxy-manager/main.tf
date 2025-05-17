locals {
  access_list_map      = { for al in data.nginxproxymanager_access_lists.access_lists.access_lists : al.name => al }
  certificate_list_map = { for cert in data.nginxproxymanager_certificates.certificates.certificates : cert.nice_name => cert }
}

data "nginxproxymanager_certificates" "certificates" {
  depends_on = [nginxproxymanager_certificate_letsencrypt.certificate]
}

data "nginxproxymanager_access_lists" "access_lists" {
  depends_on = [nginxproxymanager_access_list.access_lists]
}

resource "nginxproxymanager_proxy_host" "hosts" {
  for_each = var.service_proxies

  domain_names = each.value.domain_names

  forward_scheme = each.value.scheme
  forward_host   = each.value.ip
  forward_port   = each.value.port

  caching_enabled         = each.value.cache_assets
  allow_websocket_upgrade = each.value.websockets
  block_exploits          = each.value.block_common_exploits

  access_list_id = each.value.access_list_name != null ? local.access_list_map[each.value.access_list_name].id : null

  certificate_id  = each.value.ssl != null ? local.certificate_list_map[each.value.ssl.certificate_name].id : null
  ssl_forced      = each.value.ssl != null ? each.value.ssl.force_ssl : null
  hsts_enabled    = each.value.ssl != null ? each.value.ssl.hsts_enabled : null
  hsts_subdomains = each.value.ssl != null ? each.value.ssl.hsts_subdomains : null
  http2_support   = each.value.ssl != null ? each.value.ssl.http2_support : null

  locations = [
    for location in each.value.custom_locations : {
      path            = location.location
      forward_scheme  = location.forward_scheme
      forward_host    = location.forward_hostname_or_ip
      forward_port    = location.forward_port
      advanced_config = location.advanced_config
    }
  ]
}

resource "nginxproxymanager_access_list" "access_lists" {
  for_each = var.access_lists

  name = each.value.name

  access = [
    for access in each.value.access : {
      directive = access.directive
      address   = access.address
    }
  ]
}

resource "nginxproxymanager_certificate_letsencrypt" "certificate" {
  for_each = {
    for key, value in var.ssl_certificates : key => value
  }

  domain_names      = each.value.domain_names
  letsencrypt_email = each.value.letsencrypt_email
  letsencrypt_agree = true

  dns_provider             = each.value.dns_provider
  dns_challenge            = each.value.dns_challenge
  dns_provider_credentials = "${each.value.credential_prefix}${each.value.dns_provider_credential}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "nginxproxymanager_settings" "settings" {
  default_site = {
    page = "html"
    html = file("${path.module}/404.html")
  }
}
