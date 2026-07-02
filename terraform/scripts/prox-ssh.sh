#!/bin/bash
# SSH into a Proxmox LXC container using its name.
# Usage: prox-ssh <lxc-name> [root]

if ! command -v bws >/dev/null 2>&1; then
    echo "Error: bws command not found" >&2
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq command not found" >&2
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "Error: python3 command not found" >&2
    exit 1
fi

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Usage: $0 <lxc-name> [root]" >&2
    exit 1
fi

LXC_NAME=$(echo "$1" | tr '[:upper:]' '[:lower:]')
SSH_USER=${2:-docker-lxc}

# bws outputs literal newlines inside JSON strings (invalid JSON); python3 handles this.
# All secrets are fetched in one call and delimited with ---END--- for safe multiline splitting.
BWS_EXTRACTED=$(bws secret list --output json --color no | python3 -c "
import sys, json
secrets = json.load(sys.stdin)
by_key = {s['key']: s['value'] for s in secrets}
keys = sys.argv[1:]
missing = [k for k in keys if k not in by_key]
if missing:
    print('Error: missing BWS secrets: ' + ', '.join(missing), file=sys.stderr)
    sys.exit(1)
for k in keys:
    print(by_key[k])
    print('---END---')
" "proxmox_endpoint" "proxmox_terraform_token" "lxc-ssh-key-private-${LXC_NAME}-${SSH_USER}") || exit 1

PROXMOX_ENDPOINT=$(echo "$BWS_EXTRACTED" | awk '/---END---/{found++; next} found==0{print}')
PROXMOX_TOKEN=$(echo "$BWS_EXTRACTED"    | awk '/---END---/{found++; next} found==1{print}')
SSH_KEY=$(echo "$BWS_EXTRACTED"          | awk '/---END---/{found++; next} found==2{print}')

PROXMOX_ENDPOINT="${PROXMOX_ENDPOINT%/}"

# Find the container across all nodes by hostname
CONTAINERS=$(curl -sf -k \
    -H "Authorization: PVEAPIToken=${PROXMOX_TOKEN}" \
    "${PROXMOX_ENDPOINT}/api2/json/cluster/resources")

CONTAINER=$(echo "$CONTAINERS" | jq -r --arg name "$LXC_NAME" \
    '.data[] | select(.type == "lxc" and .name == $name)')

if [ -z "$CONTAINER" ]; then
    echo "Error: no LXC container named '${LXC_NAME}' found in Proxmox" >&2
    exit 1
fi

NODE=$(echo "$CONTAINER" | jq -r '.node')
VMID=$(echo "$CONTAINER" | jq -r '.vmid')

# Get the container's network config to extract its IP
IFACES=$(curl -sf -k \
    -H "Authorization: PVEAPIToken=${PROXMOX_TOKEN}" \
    "${PROXMOX_ENDPOINT}/api2/json/nodes/${NODE}/lxc/${VMID}/interfaces")

IP=$(echo "$IFACES" | jq -r \
    '[.data[] | select(.name != "lo") | .inet // empty] | first' \
    | cut -d/ -f1)

if [ -z "$IP" ]; then
    echo "Error: could not determine IP for '${LXC_NAME}'" >&2
    exit 1
fi

echo "Connecting to ${LXC_NAME} (${IP}) as ${SSH_USER}..."

KEY_FILE=$(mktemp)
chmod 600 "$KEY_FILE"
trap 'rm -f "$KEY_FILE"' EXIT
printf '%s\n' "$SSH_KEY" > "$KEY_FILE"

ssh -i "$KEY_FILE" \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    "${SSH_USER}@${IP}"
