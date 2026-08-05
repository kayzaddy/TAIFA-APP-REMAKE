"""Platform-wide production readiness system checks (beyond payments gates)."""
from __future__ import annotations

from django.conf import settings
from django.core.checks import Error, register

from payments.production_gates import is_production_runtime


@register()
def check_platform_production_runtime(app_configs, **kwargs):
    """Refuse national-scale-unsafe defaults when DEBUG=false."""
    errors: list[Error] = []
    if not is_production_runtime():
        return errors

    secret = getattr(settings, "SECRET_KEY", "") or ""
    if secret in {"", "dev-insecure-change-me"} or len(secret) < 32:
        errors.append(
            Error(
                "DJANGO_SECRET_KEY must be a strong unique secret in production (≥32 chars).",
                id="platform.E001",
            )
        )

    engine = settings.DATABASES.get("default", {}).get("ENGINE", "")
    if "sqlite" in engine:
        errors.append(
            Error(
                "SQLite is not allowed when DEBUG=false. Set DATABASE_URL to Postgres.",
                id="platform.E002",
            )
        )

    if getattr(settings, "CELERY_TASK_ALWAYS_EAGER", True):
        errors.append(
            Error(
                "CELERY_TASK_ALWAYS_EAGER must be false in production (real workers required).",
                id="platform.E003",
            )
        )

    cache_backend = (
        settings.CACHES.get("default", {}).get("BACKEND", "") if settings.CACHES else ""
    )
    if "locmem" in cache_backend.lower():
        errors.append(
            Error(
                "LocMem cache is not allowed in production. Set CACHE_URL to Redis "
                "so throttles and sessions share state across replicas.",
                id="platform.E004",
            )
        )

    if getattr(settings, "TAIFA_ALLOW_STUB_ADAPTERS", False):
        errors.append(
            Error(
                "TAIFA_ALLOW_STUB_ADAPTERS must be false in production "
                "(AI/identity/government stubs and simulated payment rails forbidden).",
                id="platform.E005",
            )
        )

    # Simulated payment rails must not be the only path when stubs are banned —
    # at least one live-capable rail config should exist for national payments.
    from payments.gateways.airtel import AirtelConfig
    from payments.gateways.card_acquirer import CardAcquirerConfig
    from payments.gateways.mpesa import MpesaConfig
    from payments.gateways.selcom import SelcomConfig

    mpesa = MpesaConfig.from_settings(getattr(settings, "MPESA", {}) or {})
    live_rail = any(
        [
            mpesa.is_configured,
            AirtelConfig.from_settings().is_configured,
            SelcomConfig.from_settings().is_configured,
            CardAcquirerConfig.from_settings().is_configured,
        ]
    )
    if not live_rail:
        errors.append(
            Error(
                "At least one live payment rail must be configured in production "
                "(MPESA_*, AIRTEL_*, SELCOM_*, or CARD_ACQUIRER_*).",
                id="platform.E006",
            )
        )

    return errors
