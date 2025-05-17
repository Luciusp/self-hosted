# Bitwarden Secrets
Initializes a project and sets up a list of secrets provided via `secrets.tfvars` by making use of the Bitwarden Secrets Manager.

## Prerequisites
- Have a machine account set up in Bitwarden Secrets with an access key created.

## Usage
1. Export your Bitwarden Secrets access key:
    ```bash
    $ export BWS_ACCESS_TOKEN=<your access token>
    ```
1. Create a file called `secrets.tfvars` in this directory.
1. Fill in secrets values as a map. For example:
   ```hcl
    secrets_map = {
        "cloudflare_api_token"       = "asdfghjkl123456789"
        "nginxproxymanager_email"    = "test@acme.com"
        "nginxproxymanager_password" = "replaceMe!"
        "nginxproxymanager_url"      = "http://10.1.1.1:81"
    }
   ```
1. Run `terragrunt apply`.
