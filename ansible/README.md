# Ansible Perimeter Bootstrap

This directory contains the Ansible playbook that bootstraps the **Perimeter**:
the always-on, non-Proxmox host that gates access to the home lab. The playbook
installs Docker on the Perimeter and brings up the perimeter services (Caddy,
Authentik, Pi-hole, Cloudflare DDNS, Duck DNS).

The per-service secret generation and `.env` setup that the playbook performs is
tracked in [todo.md](todo.md).

## Prerequisites

The playbook is run from a **provisioner** machine (the Ansible control node).
Install the following there.

- **Ansible**: `ansible` (and `ansible-core`)
- **Bitwarden Secrets CLI** (`bws`): `pip install bitwarden-sdk`
- **Ansible roles & collections**:
  - Docker role: `ansible-galaxy role install geerlingguy.docker`
  - `community.docker` collection (used by the playbook's `docker_compose_v2` tasks): `ansible-galaxy collection install community.docker`
  - `bitwarden.secrets` collection (used to manage bws secrets, see todo.md step 4): `ansible-galaxy collection install bitwarden.secrets`

## Before running the playbook

One-time manual setup. Complete these before the first run.

### 1. Prepare the Perimeter server

Provision a non-Proxmox host. This is the machine the playbook will target.

### 2. Create the `ansible` user on the Perimeter

SSH into the Perimeter and run:

```sh
# create user
sudo useradd -m ansible && \
# add to sudo group
sudo usermod -aG sudo ansible && \
# allow passwordless sudo
echo "ansible ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/ansible && \
# add temporary password
sudo passwd ansible
```

### 3. Create an SSH key and store it in bws

On the provisioner, generate a key and copy the public key to the Perimeter:

```sh
ssh-keygen -t ed25519 -f ~/.ssh/ansible-perimeter -N "" && \
ssh-copy-id -i ~/.ssh/ansible-perimeter ansible@<perimeter-ip>
```

Store the private key content in bws under `perimeter/ansible/ssh_private_key`.

### 4. Proxmox Master

Store the Terraform username, password, and token in bws.

### 5. Add the `stack/config` secret to bws

```json
{
  "primary_dns": "<your-domain>",
  "perimeter_ip": "<perimeter-ip>",
  "proxmox_master_ip": "<proxmox-master-ip>",
  "admin_email": "<admin-email>"
}
```

### 6. Fill in `inventory.yaml`

Point the inventory at the Perimeter you prepared:

```yaml
perimeter:
  hosts:
    node1:
      ansible_host: "<perimeter-ip>" # Perimeter IP address
      ansible_ssh_private_key_file: "/tmp/ansible-ssh" # key is automatically pulled
all:
  vars:
    ansible_user: ansible # user created in step 2
```

### 7. Create `secret-ids.yml`

Copy `secret-ids.example.yml` to `secret-ids.yml` (gitignored) and set the Bitwarden secret IDs the playbook looks up.

## Running the playbook

From the `ansible/` directory:

```sh
ansible-playbook -i inventory.yaml bootstrap.yaml
```
