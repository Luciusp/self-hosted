variable "proxmox_endpoint" {
  description = "The Proxmox endpoint to use for authentication"
  type        = string
}

variable "proxmox_api_token" {
  description = "The Proxmox API token to use for authentication"
  type        = string
}

variable "proxmox_terraform_username" {
  description = "The Proxmox username to use for SSH authentication"
  type        = string
}

variable "proxmox_terraform_user_password" {
  description = "The Proxmox password to use for SSH authentication"
  type        = string
}

variable "bitwarden_access_token" {
  description = "The Bitwarden access token to use for retrieving secrets"
  type        = string
}

variable "bitwarden_organization_id" {
  description = "The Bitwarden organization ID to use for retrieving secrets"
  type        = string
}

variable "lxc_name" {
  description = "The name of the LXC container"
  type        = string
}

variable "default_gateway" {
  description = "The default network gateway the LXC will use (ideally your router)"
  type        = string
}

variable "static_ip" {
  description = "The static IP address for the LXC container"
  type        = string
}

variable "os_template" {
  description = "The OS template to use for the LXC container. Typically added via the PVE web UI"
  type        = string
}

variable "os_type" {
  description = "The OS type for the LXC container"
  type        = string
  default     = "unmanaged"
  validation {
    condition     = contains(["alpine", "archlinux", "centos", "devuan", "fedora", "gentoo", "nixos", "opensuse", "debian", "ubuntu", "unmanaged"], var.os_type)
    error_message = "OS type must be alpine, archlinux, centos, devuan, fedora, gentoo, nixos, opensuse, debian, ubuntu, or unmanaged."
  }
}

variable "disk_size_gb" {
  description = "The size of the disk for the LXC container in GB"
  type        = number
  default     = 4
}

variable "destination_node_name" {
  description = "The proxmox node this LXC container will be provisioned on"
  type        = string
}

variable "ssh_key" {
  description = "The SSH key to use for the LXC container"
  type        = string
  default     = ""
}

variable "memory_mb" {
  description = "The amount of memory to allocate to the LXC container in MB"
  type        = number
  default     = 512
}

variable "swap_mb" {
  description = "The amount of swap to allocate to the LXC container in MB"
  type        = number
  default     = 512
}

variable "cpu_cores" {
  description = "The number of CPU cores to allocate to the LXC container"
  type        = number
  default     = 1
}

variable "cpu_limit" {
  description = "The CPU limit for the LXC container"
  type        = number
  default     = 0
}

variable "cpu_units" {
  description = "The CPU units for the LXC container"
  type        = number
  default     = 1024
}

variable "cpu_arch" {
  description = "The CPU architecture for the LXC container"
  type        = string
  default     = "amd64"

  validation {
    condition     = contains(["amd64", "arm64", "armhf", "i386"], var.cpu_arch)
    error_message = "CPU architecture must be amd64, arm64, armhf, or i386."
  }
}
