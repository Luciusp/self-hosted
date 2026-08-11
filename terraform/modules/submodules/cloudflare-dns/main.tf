data "cloudflare_zone" "this" {
  name = var.domain
}

resource "cloudflare_dns_record" "this" {
  name    = "${var.subdomain}.${var.domain}"
  ttl     = 3600
  type    = "CNAME"
  comment = "Managed by Terraform"
  content = var.domain
  proxied = var.proxied
  zone_id = data.cloudflare_zone.this.zone_id
}
