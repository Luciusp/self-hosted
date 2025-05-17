# NGINX Proxy Manager
Adds proxy hosts, access lists, and certificates to Nginx Proxy Manager (NPM)

## Prerequisites
- This terragrunt service relies on the Bitwarden Secrets definition. You will need the following

## Usage
1. Apply the Bitwarden Secrets service with your NPM login credentials.
1. Create a file in this directory called `secrets.tfvars` and place any domains you'd like to use in it. Right now this is more tailored to me, so it only supports a single map value with the name `hf_domain`:
    ```hcl
    hf_domain = "acme.com"
    ```
1. Run `terragrunt apply`.
