#!/usr/bin/env bash
# Encrypted Postgres backup for TAIFA.
# Usage: ./deploy/scripts/backup_postgres.sh
# Requires: pg_dump, openssl, DATABASE_URL or PG* env, BACKUP_ENCRYPTION_KEY
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="${BACKUP_DIR:-$ROOT/var/backups}"
mkdir -p "$OUT_DIR"

: "${BACKUP_ENCRYPTION_KEY:?Set BACKUP_ENCRYPTION_KEY (passphrase)}"

DUMP="$OUT_DIR/taifa_${STAMP}.sql.gz"
ENC="$DUMP.enc"

echo "[backup] dumping database…"
pg_dump "${DATABASE_URL:?Set DATABASE_URL}" | gzip -c > "$DUMP"

echo "[backup] encrypting…"
openssl enc -aes-256-cbc -pbkdf2 -salt -in "$DUMP" -out "$ENC" -pass "pass:${BACKUP_ENCRYPTION_KEY}"
rm -f "$DUMP"

# Marker consumed by /metrics → taifa_backup_last_success_timestamp_seconds
MARKER="$ROOT/var/backup_last_success"
mkdir -p "$(dirname "$MARKER")"
date +%s > "$MARKER"

echo "[backup] wrote $ENC"
echo "[backup] marker $MARKER"
ls -lh "$ENC"
