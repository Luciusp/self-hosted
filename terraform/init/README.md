A couple of services need to be set up before these terraform scripts can be run.

## Secrets Vault

You will need some form of external secrets store to reference for the terraform scripts. I use Bitwarden. If you use something else, you should update the `get-secrets.sh` script to match your secrets store.

## Proxmox

You will need to create an API token for the Proxmox provider to use. Follow the [docs](https://registry.terraform.io/providers/bpg/proxmox/latest/docs#api-token-authentication). Store the API token in your secrets store. It should also either be set up with a reverse proxy record with https, otherwise you will need to disable SSL verification in the provider configuration.

You'll also want to create a terraform user. First, go to the PVE shell and run:
```shell
useradd -m terraform
```
Then create a new user in the proxmox UI. Name it Terraform, put it in the PAM realm, give it admin permissions. Set the password for it via the GUI and add it to your secrets manager.

## Pihole

You will need to set up a Pihole instance to use for DNS resolution. Ideally you would set this at the router level. Store your admin password in your secrets store.

## GCS Bucket (Remote TF State)

You will need to create a GCS bucket to store the terraform state. Follow the [docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) for more information.

## Caddy
Caddy is used for reverse proxying and SSL termination. You'll need to ensure caddy admin API is enabled and available on your local network. Add this to your Caddyfile. I needed to mess with the listener since Caddy is run via docker in my setup.
```
{
	admin 0.0.0.0:2019 {
		origins localhost:2019 127.0.0.1:2019 0.0.0.0:2019
	}
}
```
