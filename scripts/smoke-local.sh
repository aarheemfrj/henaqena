#!/usr/bin/env bash
set -euo pipefail

API_URL="${API_URL:-http://127.0.0.1:4000}"
WEB_URL="${WEB_URL:-http://127.0.0.1:3100}"

check() {
  local label="$1" url="$2"
  local status
  status="$(curl -sS -o /tmp/henaqena-smoke-response -w '%{http_code}' "$url")"
  if [[ "$status" != "200" ]]; then
    echo "FAIL: $label ($status)"
    cat /tmp/henaqena-smoke-response
    exit 1
  fi
  echo "PASS: $label"
}

check "API health" "$API_URL/health"
check "API database readiness" "$API_URL/ready"
check "Areas" "$API_URL/api/areas"
check "Categories" "$API_URL/api/categories"
check "Arabic provider search" "$API_URL/api/providers?q=%D9%83%D9%87%D8%B1%D8%A8%D8%A7%D8%A6%D9%8A"
check "Platform home" "$WEB_URL/"
check "Privacy page" "$WEB_URL/privacy"
check "Delete-account page" "$WEB_URL/delete-account"
echo "Smoke test completed successfully."
