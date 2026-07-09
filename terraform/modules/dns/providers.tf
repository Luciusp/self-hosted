terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
    pihole = {
      source  = "lukaspustina/pihole"
      version = "0.3.1"
    }
  }
}

provider "cloudflare" {
  api_token = var.registrar_api_token
}

provider "pihole" {
  url      = var.pihole_host
  password = var.pihole_password
}
