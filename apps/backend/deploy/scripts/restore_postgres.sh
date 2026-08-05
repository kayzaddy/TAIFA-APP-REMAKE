#!/usr/bin/env bash
# Restore an encrypted TAIFA Postgres backup (destructive).
# Usage: ./deploy/scripts/restore_postgres.sh /path/to/taifa_*.sql.gz.enc
set -euo pipefail

ENC="${1:?encrypted backup path required}"
: "${BACKUP_ENCRYPTION_KEY:?Set BACKUP_ENCRYPTION_KEY}"
: "${DATABASE_URL:?Set DATABASE_URL}"

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

echo "[restore] decrypting $ENC…"
openssl enc -d -aes-256-cbc -pbkdf2 -in "$ENC" -out "$TMP" -pass "pass:${BACKUP_ENCRYPTION_KEY}"

echo "[restore] loading into database (this replaces schema/data)…"
gunzip -c "$TMP" | psql "$DATABASE_URL"

echo "[restore] complete — run: python manage.py check && curl -sf localhost/readyz"
