#!/usr/bin/env bash
# Idempotent perimeter stack initializer.
# Spins up Caddy, Authentik, Pi-hole, and Cloudflare DDNS on the perimeter RPi.
# Secrets are generated once and stored in Bitwarden Secrets (BWS).
# Safe to re-run: existing secrets/containers/DNS records are left untouched.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

# ─── colours ────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
info() { echo -e "${CYAN}[INFO]${NC}  $*" >&2; }
success() { echo -e "${GREEN}[OK]${NC}    $*" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*" >&2; }
die() {
	echo -e "${RED}[ERROR]${NC} $*" >&2
	exit 1
}

# ─── BWS helpers ────────────────────────────────────────────────────────────
# NOTE: `bws secret list` embeds literal (unescaped) newlines inside JSON
# string values for multi-line secrets (e.g. the SSH private key below),
# which makes the output invalid JSON for jq. python3's json module tolerates
# this, so it's used here instead — same workaround as terraform/scripts/prox-ssh.sh.

# bws_get KEY  — returns the secret value or empty string if not found
bws_get() {
	bws secret list --output json --color no 2>/dev/null |
		python3 -c '
import sys, json
key = sys.argv[1]
data = json.load(sys.stdin)
for s in data:
    if s.get("key") == key:
        print(s.get("value", ""))
        break
' "$1"
}

# bws_set KEY VALUE  — creates or updates a secret
# BWS_PROJECT_ID (set via .env or prompt) is required for creating new secrets.
bws_set() {
	local key="$1" value="$2"
	local existing_id
	existing_id=$(bws secret list --output json --color no 2>/dev/null |
		python3 -c '
import sys, json
key = sys.argv[1]
data = json.load(sys.stdin)
for s in data:
    if s.get("key") == key:
        print(s.get("id", ""))
        break
' "$key")
	if [[ -n "$existing_id" ]]; then
		bws secret edit "$existing_id" --value "$value" >/dev/null
	else
		# `--` prevents clap from treating values that start with '-'
		# (e.g. "-----BEGIN OPENSSH PRIVATE KEY-----") as flags.
		bws secret create -- "$key" "$value" "$BWS_PROJECT_ID" >/dev/null
	fi
}

# resolve_secret KEY GENERATOR
# If the secret exists in BWS, returns its value. Otherwise generates with GENERATOR,
# stores in BWS, and returns the value. Prints the value to stdout.
resolve_secret() {
	local key="$1" generator="$2"
	local val
	val=$(bws_get "$key")
	if [[ -z "$val" ]]; then
		val=$(eval "$generator")
		info "Generated new secret: $key"
		bws_set "$key" "$val"
	else
		info "Secret already exists, reusing: $key"
	fi
	echo "$val"
}

# ─── SSH helper ─────────────────────────────────────────────────────────────
# SSH_KEY_FILE is a temp file path set during the SSH bootstrap phase
SSH_KEY_FILE=""
rpi() { ssh -o StrictHostKeyChecking=no -i "${SSH_KEY_FILE}" "${SSH_USER}@${PERIMETER_IP}" "$@"; }

# ─── wait_healthy URL ────────────────────────────────────────────────────────
wait_healthy() {
	local url="$1" label="${2:-service}" timeout=120 elapsed=0
	info "Waiting for $label to be healthy ($url)..."
	until curl -sf --max-time 5 "$url" >/dev/null 2>&1; do
		sleep 5
		elapsed=$((elapsed + 5))
		[[ $elapsed -ge $timeout ]] && die "$label did not become healthy within ${timeout}s"
		echo -n "."
	done
	echo ""
	success "$label is healthy"
}

# ─── PHASE 0: PREFLIGHT — LOCAL DEPS (before prompts) ──────────────────────
echo ""
info "Checking local dependencies..."
for cmd in bws ssh ssh-keygen sshpass curl jq python3; do
	command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
done
success "All local dependencies present"

# ─── PHASE 0b: USER INPUTS ──────────────────────────────────────────────────
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║      Perimeter Stack Initializer             ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
echo ""

if [[ -f "$ENV_FILE" ]]; then
	info "Loading defaults from ${ENV_FILE}"
	set -a
	# shellcheck disable=SC1090
	source "$ENV_FILE"
	set +a
fi

if [[ -z "${BWS_ACCESS_TOKEN:-}" ]]; then
	read -rsp "BWS Access Token: " BWS_ACCESS_TOKEN
	echo ""
fi
export BWS_ACCESS_TOKEN

# Verify BWS auth immediately after token entry
bws secret list >/dev/null 2>&1 || die "BWS authentication failed — check your access token"
success "BWS authentication OK"

if [[ -z "${BWS_PROJECT_ID:-}" ]]; then
	read -rp "BWS Project ID (secrets are created under this project): " BWS_PROJECT_ID
fi
[[ -n "$BWS_PROJECT_ID" ]] || die "BWS_PROJECT_ID is required"

PERIMETER_IP="${PERIMETER_IP:-}"
while [[ -z "$PERIMETER_IP" ]]; do
	read -rp "Perimeter IP address (required, e.g. 192.168.0.216): " PERIMETER_IP
	[[ -z "$PERIMETER_IP" ]] && warn "Perimeter IP is required"
done
if [[ -z "${SSH_USER:-}" ]]; then
	read -rp "SSH user on RPi [pi]: " SSH_USER
fi
SSH_USER="${SSH_USER:-pi}"
PROXMOX_IP="${PROXMOX_IP:-}"
while [[ -z "$PROXMOX_IP" ]]; do
	read -rp "Proxmox IP address (required, e.g. 192.168.0.2): " PROXMOX_IP
	[[ -z "$PROXMOX_IP" ]] && warn "Proxmox IP is required"
done
if [[ -z "${PROXMOX_PORT:-}" ]]; then
	read -rp "Proxmox port [8006]: " PROXMOX_PORT
fi
PROXMOX_PORT="${PROXMOX_PORT:-8006}"
if [[ -z "${CF_API_TOKEN:-}" ]]; then
	read -rp "Cloudflare API token (DNS edit scope): " CF_API_TOKEN
fi
if [[ -z "${DOMAIN:-}" ]]; then
	read -rp "Domain (e.g. example.com): " DOMAIN
fi
if [[ -z "${TZ_INPUT:-}" ]]; then
	read -rp "Timezone [America/Los_Angeles]: " TZ_INPUT
fi
TZ_INPUT="${TZ_INPUT:-America/Los_Angeles}"

# ─── PHASE 0c: SSH KEY BOOTSTRAP ────────────────────────────────────────────
echo ""
info "Bootstrapping SSH key..."

SSH_KEY_DIR=$(mktemp -d)
chmod 700 "$SSH_KEY_DIR"
trap 'rm -rf "$SSH_KEY_DIR"' EXIT
SSH_KEY_FILE="$SSH_KEY_DIR/perimeter"

_stored_ssh_key=$(bws_get "perimeter/self/ssh_key")
if [[ -n "$_stored_ssh_key" ]]; then
	info "SSH key found in BWS — reusing"
	printf '%s\n' "$_stored_ssh_key" >"$SSH_KEY_FILE"
	chmod 600 "$SSH_KEY_FILE"
else
	warn "No SSH key found in BWS. A new ed25519 key will be generated and pushed to the RPi."
	_rpi_password="${RPI_PASSWORD:-}"
	if [[ -z "$_rpi_password" ]]; then
		read -rsp "RPi password for ${SSH_USER}@${PERIMETER_IP}: " _rpi_password
		echo ""
	fi

	info "Generating ed25519 keypair..."
	ssh-keygen -t ed25519 -C "perimeter-init@$(hostname)" -N "" -f "$SSH_KEY_FILE" >/dev/null

	info "Pushing public key to ${SSH_USER}@${PERIMETER_IP}..."
	sshpass -p "$_rpi_password" ssh-copy-id \
		-o StrictHostKeyChecking=no \
		-i "$SSH_KEY_FILE" \
		"${SSH_USER}@${PERIMETER_IP}" ||
		die "Failed to push public key to RPi — check password and ensure SSH is running"
	rm -f "${SSH_KEY_FILE}.pub"

	info "Storing private key in BWS as perimeter/self/ssh_key..."
	bws_set "perimeter/self/ssh_key" "$(cat "$SSH_KEY_FILE")"
	success "SSH key generated and stored in BWS"
fi

# ─── PHASE 0d: REMOTE PREFLIGHT ─────────────────────────────────────────────
echo ""
info "Verifying remote connectivity..."

ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i "${SSH_KEY_FILE}" "${SSH_USER}@${PERIMETER_IP}" true ||
	die "SSH connection failed to ${SSH_USER}@${PERIMETER_IP}"
success "SSH connection to ${PERIMETER_IP} OK"

rpi "command -v docker >/dev/null 2>&1" || die "docker not found on perimeter RPi"
success "Docker present on RPi"

# ─── PHASE 1: RESOLVE SECRETS ───────────────────────────────────────────────
echo ""
info "Resolving secrets (generating new ones only where needed)..."

PG_PASS=$(resolve_secret "perimeter/authentik/pg_pass" "openssl rand -base64 32 | tr -d '\n'")
AUTHENTIK_SECRET_KEY=$(resolve_secret "perimeter/authentik/secret_key" "openssl rand -base64 60 | tr -d '\n'")
BOOTSTRAP_TOKEN=$(resolve_secret "perimeter/authentik/bootstrap_token" "openssl rand -hex 32")
PIHOLE_PASSWORD=$(resolve_secret "perimeter/pihole/api_password" "openssl rand -base64 24 | tr -d '\n'")

# Store user-provided values idempotently
_stored_cf=$(bws_get "perimeter/cloudflare/api_token")
if [[ -z "$_stored_cf" ]]; then
	bws_set "perimeter/cloudflare/api_token" "$CF_API_TOKEN"
	info "Stored: perimeter/cloudflare/api_token"
else
	info "Already stored: perimeter/cloudflare/api_token"
	CF_API_TOKEN="$_stored_cf"
fi

_stored_domain=$(bws_get "perimeter/cloudflare/domain")
if [[ -z "$_stored_domain" ]]; then
	bws_set "perimeter/cloudflare/domain" "$DOMAIN"
	info "Stored: perimeter/cloudflare/domain"
else
	info "Already stored: perimeter/cloudflare/domain"
	DOMAIN="$_stored_domain"
fi

# Write/update the perimeter config JSON (always kept in sync with current values)
PERIMETER_CONFIG=$(jq -n \
	--arg caddy_host "${PERIMETER_IP}:2019" \
	--arg primary_host "${DOMAIN}" \
	--arg pihole_host "${PERIMETER_IP}:7989" \
	--arg perimeter_ip "${PERIMETER_IP}" \
	--arg proxmox_ip "${PROXMOX_IP}" \
	--arg proxmox_port "${PROXMOX_PORT}" \
	'{caddy_host: $caddy_host, primary_host_name: $primary_host, pihole_host: $pihole_host, perimeter_ip: $perimeter_ip, proxmox_ip: $proxmox_ip, proxmox_port: $proxmox_port}')
bws_set "perimeter/config" "$PERIMETER_CONFIG"
info "Config JSON stored in BWS as perimeter/config"

success "All secrets resolved"

# ─── PHASE 2: CLONE / PULL REPO ON RPi ──────────────────────────────────────
echo ""
info "Syncing repo on RPi..."

REPO_URL="https://github.com/Luciusp/self-hosted.git"
REPO_BRANCH="${REPO_BRANCH:-feat/refactor-topology}"

rpi "bash -s" <<ENDSSH
set -euo pipefail
if [ -d "\$HOME/.repos/self-hosted/.git" ]; then
    echo "Repo exists, pulling..."
    git -C "\$HOME/.repos/self-hosted" fetch origin "${REPO_BRANCH}"
    git -C "\$HOME/.repos/self-hosted" checkout "${REPO_BRANCH}"
    git -C "\$HOME/.repos/self-hosted" pull --ff-only origin "${REPO_BRANCH}"
else
    echo "Cloning repo..."
    mkdir -p "\$HOME/.repos"
    git clone --branch "${REPO_BRANCH}" "${REPO_URL}" "\$HOME/.repos/self-hosted"
fi
ENDSSH
success "Repo up-to-date on RPi"

# ─── PHASE 2b: COPY STACKS TO ~/servers ─────────────────────────────────────
# .env files live outside the git checkout so a `git pull` never touches
# secrets or clobbers local runtime state.
echo ""
info "Copying stacks to ~/servers on RPi..."

for stack in authentik caddy pihole cloudflare-ddns; do
	rpi "mkdir -p \$HOME/servers/${stack} && cp -r \$HOME/.repos/self-hosted/stacks/perimeter/${stack}/. \$HOME/servers/${stack}/" ||
		die "Failed to copy stack: ${stack}"
done
success "Stacks copied to ~/servers on RPi"

# ─── PHASE 3: WRITE .env FILES ──────────────────────────────────────────────
echo ""
info "Writing .env files on RPi..."

# authentik/.env
rpi "tee \$HOME/servers/authentik/.env > /dev/null" <<EOF
# PostgreSQL
PG_DB='authentik'
PG_USER='authentik'
PG_PASS='${PG_PASS}'

# Authentik
AUTHENTIK_SECRET_KEY='${AUTHENTIK_SECRET_KEY}'
AUTHENTIK_IMAGE='ghcr.io/goauthentik/server'
AUTHENTIK_TAG='2026.5.3'

# Bootstrap (first-start only — seeds akadmin API token)
AUTHENTIK_BOOTSTRAP_TOKEN='${BOOTSTRAP_TOKEN}'

# Ports
COMPOSE_PORT_HTTP='9000'
COMPOSE_PORT_HTTPS='9443'
EOF
success "authentik/.env written"

# caddy/.env
rpi "tee \$HOME/servers/caddy/.env > /dev/null" <<EOF
DOMAIN='${DOMAIN}'
CLOUDFLARE_API_TOKEN='${CF_API_TOKEN}'
PERIMETER_IP='${PERIMETER_IP}'
PROXMOX_IP='${PROXMOX_IP}'
PROXMOX_PORT='${PROXMOX_PORT}'
EOF
success "caddy/.env written"

# pihole/.env
rpi "tee \$HOME/servers/pihole/.env > /dev/null" <<EOF
TZ='${TZ_INPUT}'
FTLCONF_WEBSERVER_API_PASSWORD='${PIHOLE_PASSWORD}'
EOF
success "pihole/.env written"

# cloudflare-ddns/.env
rpi "tee \$HOME/servers/cloudflare-ddns/.env > /dev/null" <<EOF
CLOUDFLARE_API_TOKEN='${CF_API_TOKEN}'
DOMAINS='${DOMAIN}'
EOF
success "cloudflare-ddns/.env written"

# ─── PHASE 5: START STACKS ──────────────────────────────────────────────────
echo ""
info "Starting stacks on RPi..."

for stack in authentik caddy pihole cloudflare-ddns; do
	info "Starting $stack..."
	rpi "cd \$HOME/servers/${stack} && docker compose up -d" ||
		die "Failed to start stack: $stack"
	success "$stack started"
done

# ─── PHASE 6: CONFIGURE PI-HOLE DNS ─────────────────────────────────────────
echo ""
info "Waiting for Pi-hole to be ready..."
wait_healthy "http://${PERIMETER_IP}:7989/api/docs" "Pi-hole"

info "Authenticating to Pi-hole API..."
PIHOLE_AUTH_RESP=$(curl -sf -X POST \
	-H "Content-Type: application/json" \
	"http://${PERIMETER_IP}:7989/api/auth" \
	-d "{\"password\":\"${PIHOLE_PASSWORD}\"}")
PIHOLE_SESSION=$(echo "$PIHOLE_AUTH_RESP" | jq -r '.session.sid // empty')
[[ -n "$PIHOLE_SESSION" ]] || die "Pi-hole authentication failed"
success "Pi-hole session established"

# Helper: add DNS record if not already present
# Pi-hole API v6 stores custom DNS as hosts entries under /api/config/dns/hosts
# Format: "ip domain" (space-separated), URL-encoded as {ip}%20{domain}
pihole_add_dns() {
	local hostname="$1" ip="$2"
	local existing
	existing=$(curl -sf \
		-H "X-FTL-SID: ${PIHOLE_SESSION}" \
		"http://${PERIMETER_IP}:7989/api/config/dns/hosts" 2>/dev/null |
		jq -r --arg h "$hostname" '.config.dns.hosts[]? | select(test("\\s\($h)$"))' 2>/dev/null |
		head -1 || true)
	if [[ -n "$existing" ]]; then
		info "DNS record already exists: $hostname → $ip"
	else
		curl -sf -X PUT \
			-H "X-FTL-SID: ${PIHOLE_SESSION}" \
			"http://${PERIMETER_IP}:7989/api/config/dns/hosts/$(jq -nr --arg v "${ip} ${hostname}" '$v | @uri')" >/dev/null
		success "DNS record added: $hostname → $ip"
	fi
}

pihole_add_dns "proxmox.lan.${DOMAIN}" "${PERIMETER_IP}"
pihole_add_dns "pihole.lan.${DOMAIN}" "${PERIMETER_IP}"

# ─── PHASE 6b: CONFIGURE CLOUDFLARE DNS ─────────────────────────────────────
# auth.${DOMAIN} is a Public Service (docs/adr/0005) and needs a Cloudflare
# record; cloudflare-ddns only updates records that already exist, so it's
# created here as a proxied CNAME pointing at the apex domain.
echo ""
info "Configuring Cloudflare DNS for auth.${DOMAIN}..."

CF_API="https://api.cloudflare.com/client/v4"
CF_AUTH_HEADER="Authorization: Bearer ${CF_API_TOKEN}"

CF_ZONE_ID=$(curl -sf -H "$CF_AUTH_HEADER" "${CF_API}/zones?name=${DOMAIN}" |
	jq -r '.result[0].id // empty')
[[ -n "$CF_ZONE_ID" ]] || die "Could not find Cloudflare zone for ${DOMAIN}"

CF_EXISTING=$(curl -sf -H "$CF_AUTH_HEADER" \
	"${CF_API}/zones/${CF_ZONE_ID}/dns_records?type=CNAME&name=auth.${DOMAIN}" |
	jq -r '.result[0].id // empty')

if [[ -n "$CF_EXISTING" ]]; then
	info "Cloudflare CNAME already exists: auth.${DOMAIN} → ${DOMAIN}"
else
	CF_CREATE_RESP=$(curl -sf -X POST \
		-H "$CF_AUTH_HEADER" \
		-H "Content-Type: application/json" \
		"${CF_API}/zones/${CF_ZONE_ID}/dns_records" \
		-d "{\"type\":\"CNAME\",\"name\":\"auth.${DOMAIN}\",\"content\":\"${DOMAIN}\",\"ttl\":1,\"proxied\":true}")
	echo "$CF_CREATE_RESP" | jq -e '.success == true' >/dev/null ||
		die "Failed to create Cloudflare CNAME for auth.${DOMAIN}: $CF_CREATE_RESP"
	success "Cloudflare CNAME created: auth.${DOMAIN} → ${DOMAIN}"
fi

# ─── PHASE 6c: CREATE authentik_api_token_tf ────────────────────────────────
# Authentik healthcheck runs after all DNS records (Pi-hole + Cloudflare) are
# configured, so that the service is fully reachable via its public hostname.
echo ""
info "Waiting for Authentik to be ready..."
wait_healthy "http://${PERIMETER_IP}:9000/-/health/ready/" "Authentik"

AUTHENTIK_API="http://${PERIMETER_IP}:9000/api/v3"
AUTH_HEADER="Authorization: Bearer ${BOOTSTRAP_TOKEN}"

info "Checking for existing token: authentik_api_token_tf..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
	-H "$AUTH_HEADER" \
	"${AUTHENTIK_API}/core/tokens/authentik_api_token_tf/")

if [[ "$HTTP_STATUS" == "200" ]]; then
	info "Token authentik_api_token_tf already exists — skipping creation"
else
	info "Creating token: authentik_api_token_tf..."
	CREATE_RESP=$(curl -sf -X POST \
		-H "$AUTH_HEADER" \
		-H "Content-Type: application/json" \
		"${AUTHENTIK_API}/core/tokens/" \
		-d '{"identifier":"authentik_api_token_tf","intent":"api","expiring":false,"description":"Terraform provider token"}')
	echo "$CREATE_RESP" | jq -e '.identifier' >/dev/null ||
		die "Failed to create authentik_api_token_tf: $CREATE_RESP"
	success "Token created"
fi

info "Retrieving token key..."
KEY_RESP=$(curl -sf \
	-H "$AUTH_HEADER" \
	"${AUTHENTIK_API}/core/tokens/authentik_api_token_tf/view_key/")
AUTHENTIK_API_TOKEN=$(echo "$KEY_RESP" | jq -r '.key // empty')
[[ -n "$AUTHENTIK_API_TOKEN" ]] || die "Could not retrieve key for authentik_api_token_tf"

bws_set "perimeter/authentik/api_token_tf" "$AUTHENTIK_API_TOKEN"
success "authentik_api_token_tf key stored in BWS as perimeter/authentik/api_token_tf"

# ─── PHASE 7: WRITE refresh-envs.sh ON RPi ──────────────────────────────────
echo ""
info "Writing refresh-envs.sh on RPi..."

rpi "tee \$HOME/refresh-envs.sh > /dev/null && chmod +x \$HOME/refresh-envs.sh" <<'ENDSSH'
#!/usr/bin/env bash
# Re-fetches all perimeter stack secrets from BWS and rewrites .env files.
# Run manually or via systemd timer before docker compose up.
set -euo pipefail

command -v docker >/dev/null 2>&1 || { echo "docker not found"; exit 1; }
[[ -n "${BWS_ACCESS_TOKEN:-}" ]] || { echo "BWS_ACCESS_TOKEN not set"; exit 1; }

# Neither bws nor jq is installed natively on this host; run the official
# CLIs via Docker so docker is the only dependency this script needs.
bws() {
    docker run --rm -e BWS_ACCESS_TOKEN ghcr.io/bitwarden/bws:latest "$@"
}
jq() {
    docker run --rm -i ghcr.io/jqlang/jq:latest "$@"
}

# Only single-line secrets are fetched here (passwords/tokens/domain), so
# plain jq parsing is safe — unlike the SSH private key handled in init.sh,
# none of these values contain embedded newlines that would break the JSON.
bws_get() {
    bws secret list --output json --color no 2>/dev/null |
        jq -r --arg k "$1" '.[] | select(.key == $k) | .value // empty' |
        head -1
}

STACK_BASE="$HOME/servers"

PG_PASS=$(bws_get            "perimeter/authentik/pg_pass")
AUTHENTIK_SECRET_KEY=$(bws_get "perimeter/authentik/secret_key")
BOOTSTRAP_TOKEN=$(bws_get    "perimeter/authentik/bootstrap_token")
PIHOLE_PASSWORD=$(bws_get    "perimeter/pihole/api_password")
CF_API_TOKEN=$(bws_get       "perimeter/cloudflare/api_token")
DOMAIN=$(bws_get             "perimeter/cloudflare/domain")
PERIMETER_CONFIG=$(bws_get   "perimeter/config")
PERIMETER_IP=$(echo "$PERIMETER_CONFIG" | jq -r '.perimeter_ip // empty')
PROXMOX_IP=$(echo "$PERIMETER_CONFIG" | jq -r '.proxmox_ip // empty')
PROXMOX_PORT=$(echo "$PERIMETER_CONFIG" | jq -r '.proxmox_port // empty')
TZ_INPUT=$(cat "${STACK_BASE}/pihole/.env" 2>/dev/null | grep '^TZ=' | cut -d= -f2 | tr -d "'" || echo "America/Los_Angeles")

cat > "${STACK_BASE}/authentik/.env" <<EOF
PG_DB='authentik'
PG_USER='authentik'
PG_PASS='${PG_PASS}'
AUTHENTIK_SECRET_KEY='${AUTHENTIK_SECRET_KEY}'
AUTHENTIK_IMAGE='ghcr.io/goauthentik/server'
AUTHENTIK_TAG='2026.5.3'
AUTHENTIK_BOOTSTRAP_TOKEN='${BOOTSTRAP_TOKEN}'
COMPOSE_PORT_HTTP='9000'
COMPOSE_PORT_HTTPS='9443'
EOF

cat > "${STACK_BASE}/caddy/.env" <<EOF
DOMAIN='${DOMAIN}'
CLOUDFLARE_API_TOKEN='${CF_API_TOKEN}'
PERIMETER_IP='${PERIMETER_IP}'
PROXMOX_IP='${PROXMOX_IP}'
PROXMOX_PORT='${PROXMOX_PORT}'
EOF

cat > "${STACK_BASE}/pihole/.env" <<EOF
TZ='${TZ_INPUT}'
FTLCONF_WEBSERVER_API_PASSWORD='${PIHOLE_PASSWORD}'
EOF

cat > "${STACK_BASE}/cloudflare-ddns/.env" <<EOF
CLOUDFLARE_API_TOKEN='${CF_API_TOKEN}'
DOMAINS='${DOMAIN}'
EOF

echo "All .env files refreshed from BWS"
ENDSSH
success "refresh-envs.sh written to ~/refresh-envs.sh on RPi"

# ─── PHASE 8: HEALTH SUMMARY ────────────────────────────────────────────────
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    Setup Complete                            ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

print_service() {
	local name="$1" url="$2"
	if curl -sf --max-time 5 "$url" >/dev/null 2>&1; then
		echo -e "  ${GREEN}✓${NC}  $name — $url"
	else
		echo -e "  ${YELLOW}?${NC}  $name — $url (not yet reachable)"
	fi
}

print_service "Authentik" "http://${PERIMETER_IP}:9000/-/health/ready/"
print_service "Caddy admin" "http://${PERIMETER_IP}:2019/config/"
print_service "Pi-hole" "http://${PERIMETER_IP}:7989/api/docs"

echo ""
echo -e "  ${CYAN}URLs (once DNS propagates):${NC}"
echo -e "  • https://auth.${DOMAIN}"
echo -e "  • https://proxmox.lan.${DOMAIN}  (LAN only)"
echo -e "  • https://pihole.lan.${DOMAIN}  (LAN only)"
echo ""
echo -e "  ${CYAN}Next steps:${NC}"
echo -e "  1. Complete Authentik initial setup: http://${PERIMETER_IP}:9000/if/flow/initial-setup/"
echo -e "  2. Set your router's DNS server to ${PERIMETER_IP} (Pi-hole)"
echo -e "  3. Run 'terraform apply' in terraform/deploy/perimeter/authentik/"
echo -e "     (uses BWS secret: perimeter/authentik/api_token_tf)"
echo -e "  4. To refresh .env files later: BWS_ACCESS_TOKEN=<token> ~/refresh-envs.sh"
echo ""
