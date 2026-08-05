#!/usr/bin/env bash
# Verify backup decrypts and contains expected SQL (does NOT load into prod).
set -euo pipefail

ENC="${1:?encrypted backup path required}"
: "${BACKUP_ENCRYPTION_KEY:?Set BACKUP_ENCRYPTION_KEY}"

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

openssl enc -d -aes-256-cbc -pbkdf2 -in "$ENC" -out "$TMP" -pass "pass:${BACKUP_ENCRYPTION_KEY}"
gunzip -t "$TMP"
gunzip -c "$TMP" | head -c 200 | grep -q "PostgreSQL database dump"
echo "[verify] OK: $ENC decrypts and looks like a pg_dump"
