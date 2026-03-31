#!/usr/bin/env bash

set -euo pipefail

VPS_USER="${VPS_USER:-opsdf55jrdjxsadgh}"
VPS_HOST="${VPS_HOST:-srv1407636.hstgr.cloud}"
VPS_FALLBACK_HOST="${VPS_FALLBACK_HOST:-187.77.212.203}"
VPS_PORT="${VPS_PORT:-22022}"
VPS_SSH_KEY="${VPS_SSH_KEY:-/tmp/id_ed25519_vps}"
VPS_APP_DIR="${VPS_APP_DIR:-/opt/smokeshop/smokeshop-backend}"
CADDYFILE_PATH="${CADDYFILE_PATH:-/opt/patriotic-projects/vscode-proxy/Caddyfile}"

if [ ! -f "$VPS_SSH_KEY" ]; then
  echo "Missing SSH key: $VPS_SSH_KEY"
  exit 1
fi

if ! command -v rsync >/dev/null 2>&1; then
  echo "rsync is required"
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "git is required"
  exit 1
fi

retry_command() {
  local attempts="$1"
  local sleep_seconds="$2"
  shift 2

  local try
  for try in $(seq 1 "$attempts"); do
    if "$@"; then
      return 0
    fi

    if [ "$try" -lt "$attempts" ]; then
      echo "Command failed (attempt ${try}/${attempts}); retrying in ${sleep_seconds}s..."
      sleep "$sleep_seconds"
    fi
  done

  echo "Command failed after ${attempts} attempts."
  return 1
}

echo "Syncing tracked backend files to VPS (excluding local artifacts)..."
SYNC_LIST="$(mktemp)"
trap 'rm -f "$SYNC_LIST"' EXIT
RSYNC_SSH_CMD="ssh -4 -i $VPS_SSH_KEY -p $VPS_PORT -o StrictHostKeyChecking=accept-new -o ConnectTimeout=15 -o ConnectionAttempts=1"

DEPLOY_HOSTS=("$VPS_HOST")
if [ "$VPS_FALLBACK_HOST" != "$VPS_HOST" ]; then
  DEPLOY_HOSTS+=("$VPS_FALLBACK_HOST")
fi

# Only deploy tracked files from the working tree to avoid copying local artifacts.
git -C "$(dirname "$0")/.." ls-files > "$SYNC_LIST"

# Include required VPS deploy artifacts even if they are not committed yet.
for required in Dockerfile.prod docker-compose.vps.yml .env.vps.production.example .env.vps.staging.example; do
  if [ -f "$required" ] && ! grep -qx "$required" "$SYNC_LIST"; then
    echo "$required" >> "$SYNC_LIST"
  fi
done

ACTIVE_HOST=""
for host in "${DEPLOY_HOSTS[@]}"; do
  echo "Trying rsync to ${host}..."
  if retry_command 6 10 rsync -avz --delete --delete-missing-args --prune-empty-dirs \
    -e "$RSYNC_SSH_CMD" \
    --files-from "$SYNC_LIST" \
    ./ "$VPS_USER@$host:$VPS_APP_DIR/"; then
    ACTIVE_HOST="$host"
    break
  fi
done

if [ -z "$ACTIVE_HOST" ]; then
  echo "Unable to reach VPS over SSH using hosts: ${DEPLOY_HOSTS[*]}"
  exit 1
fi

echo "Preparing environment files, Caddy routes, and starting containers..."
retry_command 6 10 ssh -4 -i "$VPS_SSH_KEY" -p "$VPS_PORT" -o StrictHostKeyChecking=accept-new -o ConnectTimeout=15 -o ConnectionAttempts=1 "$VPS_USER@$ACTIVE_HOST" \
  "CADDYFILE_PATH='$CADDYFILE_PATH' VPS_APP_DIR='$VPS_APP_DIR' SMOKESHOP_DATABASE_URL='${SMOKESHOP_DATABASE_URL:-}' CLOVER_APP_ID='${CLOVER_APP_ID:-}' CLOVER_APP_SECRET='${CLOVER_APP_SECRET:-}' CLOVER_ACCESS_TOKEN='${CLOVER_ACCESS_TOKEN:-}' CLOVER_MERCHANT_ID='${CLOVER_MERCHANT_ID:-}' CLOVER_WEBHOOK_SECRET='${CLOVER_WEBHOOK_SECRET:-}' CLOVER_OAUTH_BASE_URL='${CLOVER_OAUTH_BASE_URL:-https://www.clover.com}' CLOVER_API_BASE_URL='${CLOVER_API_BASE_URL:-https://api.clover.com}' CLOVER_REDIRECT_URI='${CLOVER_REDIRECT_URI:-}' bash -s" <<'EOF'
set -euo pipefail

cd "$VPS_APP_DIR"

upsert_env_value() {
  local key="$1"
  local value="$2"
  local file="$3"
  local tmp_file

  tmp_file="$(mktemp)"
  if [ -f "$file" ]; then
    grep -v "^${key}=" "$file" > "$tmp_file" || true
  fi
  printf '%s=%s\n' "$key" "$value" >> "$tmp_file"
  mv "$tmp_file" "$file"
}

ensure_caddy_site_block() {
  local site_label="$1"
  local upstream="$2"
  local tmp_file

  tmp_file="$(mktemp)"
  awk -v site="${site_label} {" '
    BEGIN { skipping = 0 }
    $0 == site {
      skipping = 1
      next
    }
    skipping && $0 == "}" {
      skipping = 0
      next
    }
    skipping { next }
    { print }
  ' "$CADDYFILE_PATH" > "$tmp_file"
  mv "$tmp_file" "$CADDYFILE_PATH"

  cat >> "$CADDYFILE_PATH" <<CADDY_EOF

${site_label} {
    encode gzip
    reverse_proxy http://127.0.0.1:${upstream}
    log
}

CADDY_EOF
}

if [ ! -f .env.vps.production ]; then
  if [ -f .env.vps.production.example ]; then
    cp .env.vps.production.example .env.vps.production
  else
    cat > .env.vps.production <<"ENV_EOF"
NODE_ENV=production
PORT=3000
DATABASE_URL=
NEXT_PUBLIC_SITE_URL=https://neutraldevelopment.com
NEXT_PUBLIC_API_URL=https://neutraldevelopment.com
INVENTORY_MANAGER_EMAILS=
CLOVER_ACCESS_TOKEN=
CLOVER_MERCHANT_ID=
CLOVER_WEBHOOK_SECRET=
ENV_EOF
  fi
fi

if [ ! -f .env.vps.staging ]; then
  if [ -f .env.vps.staging.example ]; then
    cp .env.vps.staging.example .env.vps.staging
  else
    cat > .env.vps.staging <<"ENV_EOF"
NODE_ENV=production
PORT=3000
DATABASE_URL=
NEXT_PUBLIC_SITE_URL=https://staging.neutraldevelopment.com
NEXT_PUBLIC_API_URL=https://staging.neutraldevelopment.com
INVENTORY_MANAGER_EMAILS=
CLOVER_ACCESS_TOKEN=
CLOVER_MERCHANT_ID=
CLOVER_WEBHOOK_SECRET=
ENV_EOF
  fi
fi

upsert_env_value "NEXT_PUBLIC_SITE_URL" "https://api.neutraldevelopment.com" ".env.vps.production"
upsert_env_value "NEXT_PUBLIC_API_URL" "https://api.neutraldevelopment.com" ".env.vps.production"
upsert_env_value "NEXT_PUBLIC_SITE_URL" "https://staging-api.neutraldevelopment.com" ".env.vps.staging"
upsert_env_value "NEXT_PUBLIC_API_URL" "https://staging-api.neutraldevelopment.com" ".env.vps.staging"

DB_PASS=""
if [ -f /opt/smokeshop/smokeshop-backend/.env.postgres.local ]; then
  DB_PASS=$(sed -n "s/^POSTGRES_PASSWORD=//p" /opt/smokeshop/smokeshop-backend/.env.postgres.local)
fi

if [ -n "$DB_PASS" ]; then
  DB_PASS_ENCODED=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "$DB_PASS")
  for envfile in .env.vps.production .env.vps.staging; do
    upsert_env_value "DATABASE_URL" "postgresql://smokeshop_user:${DB_PASS_ENCODED}@host.docker.internal:5432/smokeshop" "$envfile"
  done
elif [ -n "${SMOKESHOP_DATABASE_URL:-}" ]; then
  for envfile in .env.vps.production .env.vps.staging; do
    upsert_env_value "DATABASE_URL" "${SMOKESHOP_DATABASE_URL}" "$envfile"
  done
fi

for key in CLOVER_APP_ID CLOVER_APP_SECRET CLOVER_ACCESS_TOKEN CLOVER_MERCHANT_ID CLOVER_WEBHOOK_SECRET CLOVER_OAUTH_BASE_URL CLOVER_API_BASE_URL CLOVER_REDIRECT_URI; do
  eval "val=\${${key}:-}"
  if [ -n "$val" ]; then
    for envfile in .env.vps.production .env.vps.staging; do
      upsert_env_value "$key" "$val" "$envfile"
    done
  fi
done

# Remove stale root page that may remain from old syncs and conflicts with app/route.ts.
rm -f app/page.tsx

ensure_caddy_site_block "api.neutraldevelopment.com" "3202"
ensure_caddy_site_block "staging-api.neutraldevelopment.com" "3203"
ensure_caddy_site_block "api.staging.neutraldevelopment.com" "3203"

docker compose -f docker-compose.vps.yml up -d --build
docker restart vscode-caddy

echo "Backend containers:"
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}" | grep -E "smokeshop_backend|NAMES" || true
EOF

echo "Done."
