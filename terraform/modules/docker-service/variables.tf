variable "service_name" {
  type = string
}

variable "service_port" {
  type    = number
  default = 80
}

variable "registrar_api_token" {
  type = string
}

variable "pihole_host" {
  type = string
}

variable "pihole_password" {
  type = string
}

variable "domain" {
  type = string
}

variable "subdomain" {
  type = string
}

variable "ip_target" {
  type = string
}

variable "service_privacy" {
  type = string

  validation {
    condition     = contains(["public", "private"], var.service_privacy)
    error_message = "Service privacy must be public or private."
  }
}
