A couple of services need to be set up before these terraform scripts can be run.

## Secrets Vault

You will need some form of external secrets store to reference for the terraform scripts. I use Bitwarden. If you use something else, you should update the `get-secrets.sh` script to match your secrets store.

## Proxmox

You will need to create an API token for the Proxmox provider to use. Follow the [docs](https://registry.terraform.io/providers/bpg/proxmox/latest/docs#api-token-authentication). Store the API token in your secrets store. It should also either be set up with a reverse proxy record with https, otherwise you will need to disable SSL verification in the provider configuration.

You'll also want to create a terraform user in the PAM realm. Name it terraform, give it admin permissions. You'll need to do some additional setup to allow this user to access the node via SSH. Go to the node's shell and run:

```shell
useradd -m terraform && \
chown -R terraform:terraform /var/lib/vz/snippets && \
# Create the sudoers file
cat << 'EOF' | tee /etc/sudoers.d/terraform
terraform ALL=(root) NOPASSWD: /usr/sbin/pvesm
terraform ALL=(root) NOPASSWD: /usr/sbin/qm
terraform ALL=(root) NOPASSWD: /usr/bin/tee /var/lib/vz/snippets/[a-zA-Z0-9_-]*
EOF
```

Then you can set the password for it via the GUI.

Allow snippets to be uploaded to the node's local storage by enabling the feature in the node's configuration: Storage => Local => Edit => check "Snippets".

## Pihole

You will need to set up a Pihole instance to use for DNS resolution. Ideally you would set this at the router level. Store your admin password in your secrets store.

## GCS Bucket (Remote TF State)

You will need to create a GCS bucket to store the terraform state. Follow the [docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) for more information.

## Caddy
Caddy is used for reverse proxying and SSL termination. Create a Caddy API token and put it in your secrets store.
