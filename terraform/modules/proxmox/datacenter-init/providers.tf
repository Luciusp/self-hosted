terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.92.0"
    }
    bitwarden = {
      source  = "maxlaverse/bitwarden"
      version = ">= 0.13.6"
    }
  }
}

provider "proxmox" {
  endpoint = var.pm_url
  username = var.pm_root_usr
  password = var.pm_root_pw
  insecure = true
}

provider "bitwarden" {
  experimental {
    embedded_client = true
  }
}
