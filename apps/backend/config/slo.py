"""Service Level Objectives for the TAIFA payment platform.

Tracked as documentation + Prometheus recording/alert rules. Numbers are the
contract operators commit to for a controlled banking pilot.
"""
from __future__ import annotations

# Availability / success targets (fraction of successful intervals).
SLOS: dict[str, dict] = {
    "api_availability": {
        "target": 0.9995,
        "window": "30d",
        "description": "API /readyz success rate",
        "rto_minutes": 15,
        "rpo_minutes": 5,
    },
    "ledger_availability": {
        "target": 0.9999,
        "window": "30d",
        "description": "Ledger post + read path availability",
        "rto_minutes": 5,
        "rpo_minutes": 1,
    },
    "payment_success": {
        "target": 0.999,
        "window": "30d",
        "description": "Non-risk, non-user-cancel payment success share",
    },
    "webhook_processing": {
        "target": 0.9995,
        "window": "30d",
        "description": "Accepted provider callbacks processed within SLA",
    },
}

# Platform recovery objectives (disaster / infra).
RTO_MINUTES = {
    "database_failover": 15,
    "region_failover": 60,
    "worker_restart": 5,
    "redis_failover": 10,
}
RPO_MINUTES = {
    "postgres_pitr": 5,
    "full_backup": 60,
}
