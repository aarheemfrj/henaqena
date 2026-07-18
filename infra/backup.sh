#!/usr/bin/env sh
set -eu

: "${DATABASE_URL:?DATABASE_URL is required}"
: "${BACKUP_DIR:=./backups}"
mkdir -p "$BACKUP_DIR"
stamp="$(date +%Y%m%d-%H%M%S)"
pg_dump "$DATABASE_URL" --format=custom --file="$BACKUP_DIR/henaqena-$stamp.dump"
find "$BACKUP_DIR" -type f -name 'henaqena-*.dump' -mtime +14 -delete
echo "Backup written to $BACKUP_DIR/henaqena-$stamp.dump"
