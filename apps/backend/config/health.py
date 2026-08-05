"""Enterprise health probes for liveness, readiness, startup, and dependencies.

No silent failures: every dependency check returns an explicit status so
operators and orchestrators can act without guessing.
"""
from __future__ import annotations

import time
from typing import Any

from django.conf import settings
from django.db import connection
from django.http import JsonResponse


def _ok(detail: str = "ok", **extra: Any) -> dict[str, Any]:
    return {"status": "ok", "detail": detail, **extra}


def _fail(detail: str, **extra: Any) -> dict[str, Any]:
    return {"status": "fail", "detail": detail, **extra}


def _skip(detail: str) -> dict[str, Any]:
    return {"status": "skip", "detail": detail}


def check_database() -> dict[str, Any]:
    started = time.perf_counter()
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            cursor.fetchone()
        return _ok(latency_ms=round((time.perf_counter() - started) * 1000, 2))
    except Exception as exc:  # pragma: no cover - exercised in dedicated tests
        return _fail(str(exc))


def check_redis() -> dict[str, Any]:
    """Broker reachability. Skipped when Celery runs eagerly (dev/tests)."""
    if getattr(settings, "CELERY_TASK_ALWAYS_EAGER", True) and (
        settings.DEBUG or getattr(settings, "RUNNING_TESTS", False)
    ):
        return _skip("celery eager mode")
    broker = getattr(settings, "CELERY_BROKER_URL", "") or ""
    if not broker.startswith("redis://"):
        return _skip("non-redis broker")
    started = time.perf_counter()
    try:
        import redis

        client = redis.Redis.from_url(broker, socket_connect_timeout=2, socket_timeout=2)
        client.ping()
        return _ok(latency_ms=round((time.perf_counter() - started) * 1000, 2))
    except Exception as exc:
        return _fail(str(exc))


def check_migrations() -> dict[str, Any]:
    try:
        from django.db.migrations.executor import MigrationExecutor

        executor = MigrationExecutor(connection)
        plan = executor.migration_plan(executor.loader.graph.leaf_nodes())
        if plan:
            pending = [f"{m.app_label}.{m.name}" for m, _ in plan]
            return _fail("unapplied migrations", pending=pending[:20])
        return _ok("all migrations applied")
    except Exception as exc:
        return _fail(str(exc))


def check_ledger() -> dict[str, Any]:
    """Ledger subsystem importable and last reconciliation not critically broken.

    Does not re-run full reconciliation (that is scheduled). Reports last known
    result when available.
    """
    try:
        from payments.reconciliation import last_reconciliation

        recon = last_reconciliation()
        if recon is None:
            return _ok("ledger module ready; no reconciliation run yet")
        if not recon.ok:
            return _fail("last reconciliation reported breaks", breaks=recon.break_count)
        return _ok("last reconciliation clean")
    except Exception as exc:
        return _fail(str(exc))


def check_risk_engine() -> dict[str, Any]:
    try:
        from payments.risk import RiskEngine

        engine = RiskEngine()
        # Smoke: construct and ensure evaluate callable exists.
        if not hasattr(engine, "evaluate"):
            return _fail("RiskEngine.evaluate missing")
        return _ok("risk engine available")
    except Exception as exc:
        return _fail(str(exc))


def check_payment_engine() -> dict[str, Any]:
    try:
        from payments.engine import default_engine
        from payments.orchestrator import default_orchestrator

        default_engine()
        default_orchestrator()
        return _ok("payment engine + orchestrator available")
    except Exception as exc:
        return _fail(str(exc))


def check_provider_config() -> dict[str, Any]:
    """Reports M-Pesa config presence — does not call the network (avoid flaky probes)."""
    mpesa = getattr(settings, "MPESA", {}) or {}
    env = mpesa.get("ENVIRONMENT", "unknown")
    has_key = bool(mpesa.get("CONSUMER_KEY"))
    if env == "production" and not has_key:
        return _fail("MPESA production credentials missing")
    return _ok(
        environment=str(env),
        credentials_configured=has_key,
        detail="config present" if has_key else "sandbox/offline credentials unset",
    )


def aggregate_checks(checks: dict[str, dict[str, Any]]) -> tuple[str, int]:
    """Return overall status and HTTP code. fail → 503; skip/ok → 200."""
    if any(c.get("status") == "fail" for c in checks.values()):
        return "unavailable", 503
    return "ready", 200


def liveness_payload() -> dict[str, Any]:
    return {
        "status": "ok",
        "service": "taifa-payments",
        "probe": "liveness",
    }


def readiness_payload() -> tuple[dict[str, Any], int]:
    checks = {
        "database": check_database(),
        "redis": check_redis(),
        "payment_engine": check_payment_engine(),
        "risk_engine": check_risk_engine(),
    }
    overall, code = aggregate_checks(checks)
    return {
        "status": overall,
        "probe": "readiness",
        "checks": checks,
    }, code


def startup_payload() -> tuple[dict[str, Any], int]:
    checks = {
        "database": check_database(),
        "migrations": check_migrations(),
        "payment_engine": check_payment_engine(),
    }
    overall, code = aggregate_checks(checks)
    return {
        "status": "started" if code == 200 else "starting",
        "probe": "startup",
        "checks": checks,
    }, code


def dependencies_payload() -> tuple[dict[str, Any], int]:
    checks = {
        "database": check_database(),
        "redis": check_redis(),
        "migrations": check_migrations(),
        "ledger": check_ledger(),
        "risk_engine": check_risk_engine(),
        "payment_engine": check_payment_engine(),
        "provider_config": check_provider_config(),
    }
    overall, code = aggregate_checks(checks)
    return {
        "status": overall,
        "probe": "dependencies",
        "checks": checks,
    }, code


def json_probe(payload: dict[str, Any], status: int = 200) -> JsonResponse:
    return JsonResponse(payload, status=status)
