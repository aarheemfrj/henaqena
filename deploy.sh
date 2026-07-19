#!/usr/bin/env bash

# Hena Qena production deployment for:
#   /home/maalsoft-henaqena/htdocs/henaqenawebapp
#   https://henaqena.maalsoft.com
# Run after: git pull --ff-only origin main

set -Eeuo pipefail
IFS=$'\n\t'

readonly EXPECTED_DIR="/home/maalsoft-henaqena/htdocs/henaqenawebapp"
readonly DOMAIN="henaqena.maalsoft.com"
readonly WEB_PORT="3100"
readonly API_PORT="4000"
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly APP_DIR="${HENAQENA_APP_DIR:-$SCRIPT_DIR}"
readonly API_DIR="$APP_DIR/apps/api"
readonly WEB_DIR="$APP_DIR/apps/web"
readonly API_ENV="$API_DIR/.env"
readonly WEB_ENV="$WEB_DIR/.env.production"
readonly STORAGE_DIR="$APP_DIR/storage/uploads"
readonly BACKUP_DIR="$APP_DIR/backups"

log() { printf '\n\033[1;36m[%s]\033[0m %s\n' "$(date '+%H:%M:%S')" "$*"; }
ok() { printf '\033[1;32m✓ %s\033[0m\n' "$*"; }
die() { printf '\033[1;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }
on_error() { printf '\n\033[1;31mDeployment stopped at line %s. Existing PM2 services were not deleted.\033[0m\n' "$1" >&2; }
trap 'on_error "$LINENO"' ERR

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

write_env_value() {
  local file="$1" key="$2" value="$3" escaped
  escaped="${value//\\/\\\\}"
  escaped="${escaped//\"/\\\"}"
  printf '%s="%s"\n' "$key" "$escaped" >>"$file"
}

dotenv_value() {
  local file="$1" key="$2"
  local line value
  line="$(grep -m 1 -E "^${key}=" "$file" || true)"
  value="${line#*=}"
  if [[ "$value" == \"*\" ]]; then
    value="${value#\"}"
    value="${value%\"}"
    value="${value//\\\"/\"}"
    value="${value//\\\\/\\}"
  fi
  printf '%s' "$value"
}

strip_schema_param() {
  node -e '
    const u = new URL(process.argv[1]);
    u.searchParams.delete("schema");
    process.stdout.write(u.toString());
  ' "$1"
}

wait_for_url() {
  local label="$1" url="$2" attempts="${3:-30}"
  for ((i = 1; i <= attempts; i++)); do
    if curl --fail --silent --show-error --max-time 4 "$url" >/dev/null; then
      ok "$label"
      return 0
    fi
    sleep 2
  done
  die "$label did not become ready: $url"
}

log "Preflight"
require_command git
require_command node
require_command npm
require_command curl
require_command openssl
require_command pm2

[[ -d "$APP_DIR/.git" ]] || die "Git checkout not found at $APP_DIR"
[[ -f "$API_DIR/package-lock.json" ]] || die "API package-lock.json is missing"
[[ -f "$WEB_DIR/package-lock.json" ]] || die "Web package-lock.json is missing"

node_major="$(node -p 'Number(process.versions.node.split(".")[0])')"
((node_major >= 22)) || die "Node.js 22 or newer is required; found $(node --version)"

if [[ "$APP_DIR" != "$EXPECTED_DIR" ]]; then
  printf '\033[1;33mWarning: expected %s but running from %s.\033[0m\n' "$EXPECTED_DIR" "$APP_DIR"
fi

cd "$APP_DIR"

# Clean untracked .env files (they'll be recreated if needed)
rm -f "$API_ENV" "$WEB_ENV" apps/api/.env.* apps/web/.env.* 2>/dev/null || true

# Check working tree is clean (excluding .env files)
dirty_files="$(git status --porcelain | grep -v '^\?\?' || true)"
[[ -z "$dirty_files" ]] || die "Working tree has uncommitted changes. Commit/stash server changes before deployment."

current_branch="$(git branch --show-current)"
[[ "$current_branch" == "main" ]] || die "Deployment must run from main; current branch is $current_branch"
ok "Git checkout is clean on main at $(git rev-parse --short HEAD)"

log "Production secrets"
if [[ ! -f "$API_ENV" ]]; then
  [[ -t 0 ]] || die "First deployment needs an interactive terminal to create $API_ENV"
  printf 'PostgreSQL DATABASE_URL (input is hidden): '
  IFS= read -r -s database_url
  printf '\n'
  [[ "$database_url" == postgresql://* || "$database_url" == postgres://* ]] || die "DATABASE_URL must be a PostgreSQL URL"

  admin_api_key="$(openssl rand -hex 32)"
  admin_session_secret="$(openssl rand -hex 48)"
  dashboard_guard="$(openssl rand -hex 24)"
  umask 077
  : >"$API_ENV"
  write_env_value "$API_ENV" DATABASE_URL "$database_url"
  write_env_value "$API_ENV" PORT "$API_PORT"
  write_env_value "$API_ENV" API_HOST "127.0.0.1"
  write_env_value "$API_ENV" ADMIN_API_KEY "$admin_api_key"
  write_env_value "$API_ENV" UPLOADS_DIR "$STORAGE_DIR"
  write_env_value "$API_ENV" PUBLIC_API_BASE_URL "https://$DOMAIN"
  write_env_value "$API_ENV" CORS_ORIGINS "https://$DOMAIN"
  write_env_value "$API_ENV" STORAGE_DRIVER "local"
  write_env_value "$API_ENV" ENABLE_BACKGROUND_JOBS "true"
  write_env_value "$API_ENV" GOOGLE_CLIENT_IDS ""
  write_env_value "$API_ENV" APPLE_CLIENT_IDS ""
  chmod 600 "$API_ENV"

  : >"$WEB_ENV"
  write_env_value "$WEB_ENV" PORT "$WEB_PORT"
  write_env_value "$WEB_ENV" HOSTNAME "127.0.0.1"
  write_env_value "$WEB_ENV" NEXT_PUBLIC_API_BASE_URL "https://$DOMAIN"
  write_env_value "$WEB_ENV" API_INTERNAL_BASE_URL "http://127.0.0.1:$API_PORT"
  write_env_value "$WEB_ENV" ADMIN_API_KEY "$admin_api_key"
  write_env_value "$WEB_ENV" ADMIN_DASHBOARD_PASSWORD "$dashboard_guard"
  write_env_value "$WEB_ENV" ADMIN_SESSION_SECRET "$admin_session_secret"
  chmod 600 "$WEB_ENV"
  unset database_url admin_api_key admin_session_secret dashboard_guard
  ok "Created private production environment files (mode 600)"
else
  # API .env exists, ensure WEB .env exists too
  if [[ ! -f "$WEB_ENV" ]]; then
    admin_api_key="$(grep '^ADMIN_API_KEY=' "$API_ENV" | cut -d= -f2 | tr -d '"')"
    admin_session_secret="$(openssl rand -hex 48)"
    dashboard_guard="$(openssl rand -hex 24)"
    umask 077
    : >"$WEB_ENV"
    write_env_value "$WEB_ENV" PORT "$WEB_PORT"
    write_env_value "$WEB_ENV" HOSTNAME "127.0.0.1"
    write_env_value "$WEB_ENV" NEXT_PUBLIC_API_BASE_URL "https://$DOMAIN"
    write_env_value "$WEB_ENV" API_INTERNAL_BASE_URL "http://127.0.0.1:$API_PORT"
    write_env_value "$WEB_ENV" ADMIN_API_KEY "$admin_api_key"
    write_env_value "$WEB_ENV" ADMIN_DASHBOARD_PASSWORD "$dashboard_guard"
    write_env_value "$WEB_ENV" ADMIN_SESSION_SECRET "$admin_session_secret"
    chmod 600 "$WEB_ENV"
    ok "Created missing web production environment file (mode 600)"
  fi
  chmod 600 "$API_ENV" "$WEB_ENV"
  ok "Preserving existing production environment files"
fi

mkdir -p "$STORAGE_DIR" "$BACKUP_DIR"
chmod 750 "$APP_DIR/storage" "$STORAGE_DIR" "$BACKUP_DIR"

log "Ensure PostgreSQL role and database exist"
database_url="$(dotenv_value "$API_ENV" DATABASE_URL)"
[[ -n "$database_url" ]] || die "DATABASE_URL is missing from $API_ENV"

db_json="$(node -e '
  const u = new URL(process.argv[1]);
  process.stdout.write(JSON.stringify({
    user: decodeURIComponent(u.username),
    password: decodeURIComponent(u.password),
    host: u.hostname,
    database: u.pathname.replace(/^\//, "").split("?")[0],
  }));
' "$database_url")"
db_user="$(node -e 'process.stdout.write(JSON.parse(process.argv[1]).user)' "$db_json")"
db_password="$(node -e 'process.stdout.write(JSON.parse(process.argv[1]).password)' "$db_json")"
db_host="$(node -e 'process.stdout.write(JSON.parse(process.argv[1]).host)' "$db_json")"
db_name="$(node -e 'process.stdout.write(JSON.parse(process.argv[1]).database)' "$db_json")"
unset db_json

if [[ "$db_host" == "localhost" || "$db_host" == "127.0.0.1" ]] && sudo -u postgres psql -tAc 'SELECT 1' >/dev/null 2>&1; then
  # Manual SQL-literal/identifier escaping (doubling quotes) so this works on
  # any psql version, instead of relying on psql's :'var' interpolation.
  db_user_lit="${db_user//\'/\'\'}"
  db_user_ident="${db_user//\"/\"\"}"
  db_password_lit="${db_password//\'/\'\'}"
  db_name_lit="${db_name//\'/\'\'}"
  db_name_ident="${db_name//\"/\"\"}"

  role_exists="$(sudo -u postgres psql -X -q -tAc "SELECT 1 FROM pg_roles WHERE rolname = '$db_user_lit'")"
  if [[ "$role_exists" == "1" ]]; then
    sudo -u postgres psql -X -q -v ON_ERROR_STOP=1 -c "ALTER ROLE \"$db_user_ident\" WITH LOGIN PASSWORD '$db_password_lit';"
    ok "Synced password for PostgreSQL role: $db_user"
  else
    sudo -u postgres psql -X -q -v ON_ERROR_STOP=1 -c "CREATE ROLE \"$db_user_ident\" WITH LOGIN PASSWORD '$db_password_lit';"
    ok "Created PostgreSQL role: $db_user"
  fi

  db_exists="$(sudo -u postgres psql -X -q -tAc "SELECT 1 FROM pg_database WHERE datname = '$db_name_lit'")"
  if [[ "$db_exists" != "1" ]]; then
    sudo -u postgres psql -X -q -v ON_ERROR_STOP=1 -c "CREATE DATABASE \"$db_name_ident\" OWNER \"$db_user_ident\";"
    ok "Created PostgreSQL database: $db_name"
  fi
  sudo -u postgres psql -X -q -v ON_ERROR_STOP=1 -c "GRANT ALL PRIVILEGES ON DATABASE \"$db_name_ident\" TO \"$db_user_ident\";" >/dev/null
  ok "PostgreSQL role and database verified for $db_user@$db_name"
else
  printf '\033[1;33mSkipping automatic PostgreSQL provisioning (remote host or postgres superuser access unavailable). Ensure the role/database exist manually.\033[0m\n'
fi
unset db_user db_password db_host db_name role_exists db_exists db_user_lit db_user_ident db_password_lit db_name_lit db_name_ident

log "Pre-deployment backup"
if command -v pg_dump >/dev/null 2>&1; then
  backup_file="$BACKUP_DIR/henaqena-$(date '+%Y%m%d-%H%M%S').dump"
  pg_dump_url="$(strip_schema_param "$database_url")"
  if pg_dump "$pg_dump_url" --format=custom --no-owner --no-privileges --file="$backup_file"; then
    chmod 600 "$backup_file"
    ok "Database backup: $backup_file"
  else
    [[ "${ALLOW_FIRST_DEPLOY_WITHOUT_BACKUP:-0}" == "1" ]] || die "Database backup failed. For a brand-new empty database only, rerun with ALLOW_FIRST_DEPLOY_WITHOUT_BACKUP=1."
    printf '\033[1;33mFirst deployment: continuing without a database backup.\033[0m\n'
  fi
else
  [[ "${ALLOW_FIRST_DEPLOY_WITHOUT_BACKUP:-0}" == "1" ]] || die "pg_dump is required before upgrading an existing database."
  printf '\033[1;33mpg_dump not found; continuing only because ALLOW_FIRST_DEPLOY_WITHOUT_BACKUP=1.\033[0m\n'
fi
tar -czf "$BACKUP_DIR/uploads-$(date '+%Y%m%d-%H%M%S').tar.gz" -C "$APP_DIR/storage" uploads
find "$BACKUP_DIR" -type f -mtime +14 -delete
unset database_url

log "Install and build API"
cd "$API_DIR"
npm ci
npx prisma generate
npm run build
npx prisma db push --skip-generate

if ! node dist/bootstrap-owner.js; then
  [[ -t 0 ]] || die "An OWNER account is missing; rerun interactively to create it"
  printf 'Initial OWNER name: '
  IFS= read -r owner_name
  printf 'Initial OWNER email: '
  IFS= read -r owner_email
  printf 'Initial OWNER password (12+ characters, hidden): '
  IFS= read -r -s owner_password
  printf '\n'
  [[ ${#owner_password} -ge 12 ]] || die "OWNER password must be at least 12 characters"
  OWNER_NAME="$owner_name" OWNER_EMAIL="$owner_email" OWNER_PASSWORD="$owner_password" node dist/bootstrap-owner.js
  unset owner_name owner_email owner_password
fi
npm prune --omit=dev

log "Install and build Next.js platform"
cd "$WEB_DIR"
npm ci
npm run lint
npm run build
mkdir -p .next/standalone/.next
cp -R .next/static .next/standalone/.next/static
if [[ -d public ]]; then cp -R public .next/standalone/public; fi
npm prune --omit=dev

log "Reload services with PM2"
cd "$APP_DIR"
pm2 startOrReload infra/ecosystem.config.cjs --env production --update-env
pm2 save

log "Health checks"
wait_for_url "API database readiness" "http://127.0.0.1:$API_PORT/ready"
wait_for_url "Next.js platform" "http://127.0.0.1:$WEB_PORT/"
wait_for_url "Same-domain API proxy" "http://127.0.0.1:$WEB_PORT/api/health"

ok "Deployment complete: https://$DOMAIN"
printf '\nUseful commands:\n'
printf '  pm2 status\n'
printf '  pm2 logs henaqena-api --lines 100\n'
printf '  pm2 logs henaqena-web --lines 100\n'
printf '  curl -I https://%s\n' "$DOMAIN"
