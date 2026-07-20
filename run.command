#!/bin/zsh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
API_DIR="$SCRIPT_DIR/apps/api"
WEB_DIR="$SCRIPT_DIR/apps/web"

cd "$SCRIPT_DIR"

if [ ! -d "$API_DIR/node_modules" ]; then
  echo "Installing API dependencies..."
  (cd "$API_DIR" && npm install)
fi

if [ ! -d "$WEB_DIR/node_modules" ]; then
  echo "Installing Web dependencies..."
  (cd "$WEB_DIR" && npm install)
fi

echo "Preparing Prisma client..."
(cd "$API_DIR" && npx prisma generate)

cleanup() {
  echo ""
  echo "Stopping هنا قنا local servers..."
  kill "$API_PID" "$WEB_PID" 2>/dev/null
  wait "$API_PID" "$WEB_PID" 2>/dev/null
  exit 0
}
trap cleanup INT TERM

echo "Starting API on http://127.0.0.1:4000"
(cd "$API_DIR" && npm run dev) &
API_PID=$!

echo "Starting Web on http://127.0.0.1:3100"
(cd "$WEB_DIR" && npm run dev) &
WEB_PID=$!

echo ""
echo "هنا قنا شغّالة محليًا:"
echo "  Web: http://127.0.0.1:3100"
echo "  API: http://127.0.0.1:4000"
echo "اضغط Ctrl+C لإيقاف السيرفرين."
echo ""

wait "$API_PID" "$WEB_PID"
