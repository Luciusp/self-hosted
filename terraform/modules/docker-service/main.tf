data "cloudflare_zone" "this" {
  count = var.service_privacy == "public" ? 1 : 0
  filter = {
    name = var.domain
  }
}

resource "cloudflare_dns_record" "this" {
  count   = var.service_privacy == "public" ? 1 : 0
  name    = "${var.subdomain}.${var.domain}"
  ttl     = 1
  type    = "CNAME"
  comment = "Managed by Terraform"
  content = var.domain
  proxied = true
  zone_id = data.cloudflare_zone.this[0].zone_id
}

resource "pihole_dns_record" "this" {
  count  = var.service_privacy == "private" ? 1 : 0
  domain = "${var.subdomain}.lan.${var.domain}"
  ip     = var.ip_target
}
