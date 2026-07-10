variable "bitwarden_secrets_access_token" {
  type = string
}

variable "bitwarden_secrets_organization_id" {
  type = string
}

variable "secrets_to_retrieve" {
  type = list(string)
}
