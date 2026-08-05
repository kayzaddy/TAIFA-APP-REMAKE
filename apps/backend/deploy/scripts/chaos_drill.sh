#!/usr/bin/env bash
# Chaos drills for TAIFA (compose-based). Run against a non-prod stack only.
# Usage: ./deploy/scripts/chaos_drill.sh worker|redis|web|network
set -euo pipefail

TARGET="${1:?target required: worker|redis|web|network}"
COMPOSE="${COMPOSE_FILES:--f docker-compose.prod.yml}"

case "$TARGET" in
  worker)
    echo "[chaos] killing celery workers…"
    docker compose $COMPOSE kill worker || true
    sleep 5
    docker compose $COMPOSE up -d worker
    echo "[chaos] verify: curl -sf localhost/readyz && check taifa_worker_heartbeat"
    ;;
  redis)
    echo "[chaos] pausing redis 30s…"
    docker compose $COMPOSE pause redis
    sleep 30
    docker compose $COMPOSE unpause redis
    ;;
  web)
    echo "[chaos] restarting web…"
    docker compose $COMPOSE restart web
    ;;
  network)
    echo "[chaos] adding 200ms latency via tc (requires privileged sidecar) — document-only placeholder"
    echo "Use toxiproxy or tc in a privileged netns; see docs/DISASTER_RECOVERY.md"
    ;;
  *)
    echo "unknown target"
    exit 1
    ;;
esac

echo "[chaos] drill complete for $TARGET"
