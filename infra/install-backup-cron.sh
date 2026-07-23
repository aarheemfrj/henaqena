#!/usr/bin/env bash
set -Eeuo pipefail

# Install an idempotent PostgreSQL + uploads backup schedule.
# BACKUP_INTERVAL: 3days | 6days | weekly | monthly (default: weekly)
# BACKUP_ROOT: absolute backup directory (default: /home/henaqena/backups)
INTERVAL="${BACKUP_INTERVAL:-weekly}"
ROOT="${BACKUP_ROOT:-/home/henaqena/backups}"
APP_DIR="${HENAQENA_APP_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
case "$INTERVAL" in
  3days) CRON="17 2 */3 * *";;
  6days) CRON="27 2 */6 * *";;
  weekly) CRON="37 2 * * 0";;
  monthly) CRON="47 2 1 * *";;
  *) echo "BACKUP_INTERVAL must be 3days, 6days, weekly, or monthly" >&2; exit 2;;
esac
mkdir -p "$ROOT"
chmod 700 "$ROOT"
ENTRY="$CRON cd $APP_DIR && /usr/bin/env DATABASE_URL=\"\$(grep '^DATABASE_URL=' apps/api/.env | cut -d= -f2- | tr -d '\"')\" BACKUP_DIR=\"$ROOT\" /bin/sh infra/backup.sh >> $ROOT/backup.log 2>&1"
(crontab -l 2>/dev/null | grep -v 'henaqena backup schedule' || true; echo "# henaqena backup schedule"; echo "$ENTRY") | crontab -
echo "Installed $INTERVAL backup schedule at $CRON; backups: $ROOT"
