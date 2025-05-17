terraform {
  required_providers {
    bitwarden = {
      source  = "maxlaverse/bitwarden"
      version = ">= 0.13.6"
    }
  }
}

# Configure the Bitwarden Provider
provider "bitwarden" {
  experimental {
    embedded_client = true
  }
}
