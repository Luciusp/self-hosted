variable "bitwarden_project_id" {
  type        = string
  description = "The Bitwarden Secrets project to put secrets in."
}

variable "pm_url" {
  type        = string
  description = "The Proxmox VE API URL."
}

variable "pm_root_usr" {
  type = string
  description = "Proxmox root username."
  sensitive = true
}

variable "pm_root_pw" {
  type = string
  description = "Proxmox root password."
  sensitive = true
}
