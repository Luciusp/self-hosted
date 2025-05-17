
variable "ssl_certificates" {
  type = map(object({
    domain_names            = list(string)
    letsencrypt_email       = string
    dns_challenge           = optional(bool, true)
    dns_provider            = string
    dns_provider_credential = string
    # If the token requires a prefix like `dns_cloudflare_api_token=` or something
    credential_prefix = optional(string)
  }))
  default = {}
}

variable "service_proxies" {
  type = map(object({
    # Basics
    domain_names     = list(string) # List of domain names to register
    port             = number
    scheme           = string # http or https
    access_list_name = optional(string)
    ip               = string # IP address of the service

    # Toggles
    cache_assets          = optional(bool, true)
    websockets            = optional(bool, true)
    block_common_exploits = optional(bool, true)

    # Custom Locations
    custom_locations = optional(map(object({
      location               = string
      forward_scheme         = string
      forward_hostname_or_ip = string
      forward_port           = number
      advanced_config        = optional(string)
    })), {})

    # SSL
    ssl = optional(object({
      certificate_name = string
      force_ssl        = optional(bool, true)
      http2_support    = optional(bool, true)
      hsts_enabled     = optional(bool, true)
      hsts_subdomains  = optional(bool, true)
    }))

    # Advanced
    custom_nginx_config = optional(string)
  }))

  default = {}
}

variable "access_lists" {
  type = map(object({
    name = string
    # authorizations expects a list of maps
    # with the keys "username" and "password"}
    authorizations = optional(list(map(string)))
    # access expects a list of maps with the keys "directive" and "address"
    access      = list(map(string))
    pass_auth   = optional(bool, true)
    satisfy_any = optional(bool, true)
  }))
  default = {}
}
