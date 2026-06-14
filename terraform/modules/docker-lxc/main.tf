# Calculate the next available VM ID
locals {
  all_container_vm_ids = sort(concat(
    [for c in data.proxmox_virtual_environment_containers.lxc_containers.containers : c.vm_id],
    [for v in data.proxmox_virtual_environment_vms.vms.vms : v.vm_id]
  ))
  # Get the next available VM ID by finding the highest ID and adding 1
  next_vm_id = length(local.all_container_vm_ids) > 0 ? local.all_container_vm_ids[length(local.all_container_vm_ids) - 1] + 1 : 100
}

data "proxmox_virtual_environment_containers" "lxc_containers" {}
data "proxmox_virtual_environment_vms" "vms" {}

resource "proxmox_virtual_environment_container" "lxc" {
  description = "Managed by Terraform"

  node_name = var.destination_node_name
  vm_id     = local.next_vm_id

  # newer linux distributions require unprivileged user namespaces
  unprivileged = true

  memory {
    dedicated = var.memory_mb
    swap      = var.swap_mb
  }
  initialization {
    hostname = var.lxc_name

    ip_config {
      ipv4 {
        address = var.static_ip
        gateway = var.default_gateway
      }
    }

    user_account {
      keys = [
        trimspace(tls_private_key.lxc_key.public_key_openssh)
      ]
    }
  }

  network_interface {
    name = "eth0"
  }

  cpu {
    cores        = var.cpu_cores
    units        = var.cpu_units
    limit        = var.cpu_limit
    architecture = var.cpu_arch
  }

  disk {
    datastore_id = "local-lvm"
    size         = var.disk_size_gb
  }

  operating_system {
    template_file_id = "local:vztmpl/${var.os_template}"
    type             = var.os_type
  }

  startup {
    order      = 3
    up_delay   = 60
    down_delay = 60
  }

  lifecycle {
    ignore_changes = [vm_id]
  }
}

resource "null_resource" "lxc_init" {
  depends_on = [proxmox_virtual_environment_container.lxc]

  connection {
    type        = "ssh"
    host        = split("/", var.static_ip)[0]
    user        = "root"
    private_key = tls_private_key.lxc_key.private_key_openssh
    timeout     = "5m"
  }

  provisioner "file" {
    source      = "${path.module}/init-docker-lxc.sh"
    destination = "/tmp/init-docker-lxc.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/init-docker-lxc.sh",
      "/tmp/init-docker-lxc.sh"
    ]
  }
}

resource "tls_private_key" "lxc_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "bitwarden-secrets_secret" "lxc_ssh_key" {
  depends_on = [proxmox_virtual_environment_container.lxc]
  key        = "lxc-ssh-key-private-${var.lxc_name}"
  value      = tls_private_key.lxc_key.private_key_pem
  note       = "The secret value was provided via terraform configuration"
  project_id = "45fa2894-789a-431e-afb5-b2de01285f45"
}

output "ssh_key_public" {
  value = tls_private_key.lxc_key.public_key_openssh
}
