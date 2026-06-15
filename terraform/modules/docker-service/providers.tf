terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
    caddy = {
      source  = "conradludgate/caddy"
      version = "0.2.8"
    }
  }
}

provider "cloudflare" {
  api_token = var.registrar_api_token
}

provider "caddy" {
  host = var.caddy_host
}
