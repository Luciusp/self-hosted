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

# Default initialization that always runs. Installs docker and komodo periphery
resource "null_resource" "lxc_init" {
  depends_on = [proxmox_virtual_environment_container.lxc]

  connection {
    type        = "ssh"
    host        = split("/", var.static_ip)[0]
    user        = "root"
    private_key = tls_private_key.lxc_key.private_key_openssh
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "useradd -m -s /bin/bash docker-lxc",
      "mkdir -p /home/docker-lxc/.ssh",
      "echo '${trimspace(tls_private_key.docker_lxc_user_key.public_key_openssh)}' > /home/docker-lxc/.ssh/authorized_keys",
      "chmod 700 /home/docker-lxc/.ssh",
      "chmod 600 /home/docker-lxc/.ssh/authorized_keys",
      "chown -R docker-lxc:docker-lxc /home/docker-lxc/.ssh"
    ]
  }

  provisioner "file" {
    source      = "${path.module}/init.sh"
    destination = "/tmp/init.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/init.sh",
      "/tmp/init.sh"
    ]
  }
}

# User-provided script that gets run after the default initialization
resource "null_resource" "lxc_custom_init" {
  count      = var.init_script_path != "" ? 1 : 0
  depends_on = [proxmox_virtual_environment_container.lxc, null_resource.lxc_init]

  connection {
    type        = "ssh"
    host        = split("/", var.static_ip)[0]
    user        = "root"
    private_key = tls_private_key.lxc_key.private_key_openssh
    timeout     = "5m"
  }

  provisioner "file" {
    source      = var.init_script_path
    destination = "/tmp/custom-init.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/custom-init.sh",
      "/tmp/custom-init.sh"
    ]
  }
}

# Generates key for root user
resource "tls_private_key" "lxc_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Generates key for docker-lxc user
resource "tls_private_key" "docker_lxc_user_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "bitwarden-secrets_secret" "lxc_ssh_key_root" {
  depends_on = [proxmox_virtual_environment_container.lxc]
  key        = "lxc-ssh-key-private-${var.lxc_name}-root"
  value      = tls_private_key.lxc_key.private_key_pem
  note       = "The secret value was provided via terraform configuration"
  project_id = "45fa2894-789a-431e-afb5-b2de01285f45"
}

resource "bitwarden-secrets_secret" "lxc_ssh_key_docker_lxc_user" {
  depends_on = [proxmox_virtual_environment_container.lxc]
  key        = "lxc-ssh-key-private-${var.lxc_name}-docker-lxc"
  value      = tls_private_key.docker_lxc_user_key.private_key_pem
  note       = "The secret value was provided via terraform configuration"
  project_id = "45fa2894-789a-431e-afb5-b2de01285f45"
}
