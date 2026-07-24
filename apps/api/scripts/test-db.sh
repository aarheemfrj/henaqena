#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

: "${DATABASE_URL:=postgresql://henaqena:henaqena@127.0.0.1:5434/henaqena_test?schema=public}"
export DATABASE_URL
export NODE_ENV=test
export ENABLE_BACKGROUND_JOBS=false
export ADMIN_API_KEY="${ADMIN_API_KEY:-integration-admin-key}"
export UPLOADS_DIR="${UPLOADS_DIR:-/tmp/henaqena-test-uploads}"

cleanup() {
COMPOSE=(docker compose)
if ! docker compose version >/dev/null 2>&1; then COMPOSE=(docker-compose); fi
"${COMPOSE[@]}" -f docker-compose.test.yml down -v >/dev/null 2>&1 || true
}
trap cleanup EXIT

COMPOSE=(docker compose)
if ! docker compose version >/dev/null 2>&1; then COMPOSE=(docker-compose); fi
"${COMPOSE[@]}" -f docker-compose.test.yml up -d --wait
npx prisma generate
npx prisma migrate deploy
npm run test:integration
