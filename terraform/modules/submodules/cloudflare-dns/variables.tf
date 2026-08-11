variable "registrar_api_token" {
  type        = string
  description = "Cloudflare API token for DNS management"
}

variable "domain" {
  type        = string
  description = "The domain name for the DNS record"
}

variable "subdomain" {
  type        = string
  description = "The subdomain for the DNS record"
}

variable "target" {
  type        = string
  description = "The target domain or IP address for the DNS record"
}

variable "proxied" {
  type        = bool
  default     = true
  description = "Whether the record should be proxied through Cloudflare"
}
