"""Integration catalog — single inventory of every external dependency."""
from __future__ import annotations

from django.conf import settings

from payments.gateways.airtel import AirtelConfig
from payments.gateways.card_acquirer import CardAcquirerConfig
from payments.gateways.factory import mpesa_config
from payments.gateways.selcom import SelcomConfig


def _configured(flag: bool) -> str:
    return "configured" if flag else "not_configured"


def build_catalog() -> list[dict]:
    """Return the authoritative integration inventory for certification."""
    mpesa = mpesa_config()
    airtel = AirtelConfig.from_settings()
    selcom = SelcomConfig.from_settings()
    card = CardAcquirerConfig.from_settings()
    identity = getattr(settings, "TAIFA_IDENTITY_PROVIDERS", None) or {}
    government = getattr(settings, "TAIFA_GOVERNMENT_PROVIDERS", None) or {}
    ai = getattr(settings, "TAIFA_AI_PROVIDER", None) or {}
    sms = getattr(settings, "TAIFA_SMS_PROVIDER", None) or {}
    push = getattr(settings, "TAIFA_PUSH_PROVIDER", None) or {}
    maps = getattr(settings, "TAIFA_MAPS_PROVIDER", None) or {}
    storage = getattr(settings, "TAIFA_OBJECT_STORAGE", None) or {}
    scanner = getattr(settings, "TAIFA_DOCUMENT_SCANNER", None) or {}
    outbox = getattr(settings, "TAIFA_OUTBOX_WEBHOOK_URLS", None) or []
    stubs = bool(getattr(settings, "TAIFA_ALLOW_STUB_ADAPTERS", False))

    return [
        {
            "id": "payments.mpesa",
            "name": "M-Pesa Daraja",
            "owner": "payments-platform",
            "category": "payments",
            "adapter": "payments.gateways.mpesa.MpesaGateway",
            "environment": "production" if mpesa.environment == "production" else "sandbox",
            "mode": "production" if mpesa.is_configured else ("offline_stub" if stubs else "disabled"),
            "configured": mpesa.is_configured,
            "reliability": "retry+webhook",
            "security": "oauth+tls+callback_auth",
            "observability": "prometheus+structured_logs",
        },
        {
            "id": "payments.airtel",
            "name": "Airtel Money",
            "owner": "payments-platform",
            "category": "payments",
            "adapter": "payments.gateways.airtel.AirtelMoneyGateway",
            "environment": "sandbox_or_prod",
            "mode": "production" if airtel.is_configured else ("simulated" if stubs else "disabled"),
            "configured": airtel.is_configured,
            "reliability": "retry+status_query",
            "security": "oauth+tls",
            "observability": "prometheus",
        },
        {
            "id": "payments.selcom",
            "name": "Selcom Pay",
            "owner": "payments-platform",
            "category": "payments",
            "adapter": "payments.gateways.selcom.SelcomGateway",
            "environment": "sandbox_or_prod",
            "mode": "production" if selcom.is_configured else ("simulated" if stubs else "disabled"),
            "configured": selcom.is_configured,
            "reliability": "retry+status_query",
            "security": "hmac+tls",
            "observability": "prometheus",
        },
        {
            "id": "payments.card",
            "name": "Card Acquirer",
            "owner": "payments-platform",
            "category": "payments",
            "adapter": "payments.gateways.card_acquirer.CardGateway",
            "environment": "sandbox_or_prod",
            "mode": "production" if card.is_configured else ("simulated" if stubs else "disabled"),
            "configured": card.is_configured,
            "reliability": "idempotency+status_query",
            "security": "bearer+tls+idempotency",
            "observability": "prometheus",
        },
        {
            "id": "identity.federation",
            "name": "National Identity Federation",
            "owner": "identity-platform",
            "category": "identity",
            "adapter": "integrations.identity.HttpIdentityAdapter",
            "environment": "per_provider",
            "mode": "production" if identity else ("stub" if stubs else "disabled"),
            "configured": bool(identity),
            "reliability": "circuit+retry",
            "security": "tls+api_key",
            "observability": "prometheus",
        },
        {
            "id": "ai.inference",
            "name": "AI Inference (OpenAI-compatible)",
            "owner": "ai-platform",
            "category": "ai",
            "adapter": "integrations.ai.OpenAICompatibleInferenceAdapter",
            "environment": "per_provider",
            "mode": "production" if (ai.get("base_url") and ai.get("api_key")) else ("stub" if stubs else "disabled"),
            "configured": bool(ai.get("base_url") and ai.get("api_key")),
            "reliability": "circuit+retry+timeout",
            "security": "tls+bearer",
            "observability": "prometheus+ai_os_metrics",
        },
        {
            "id": "government.authorities",
            "name": "Government Authority Reporting",
            "owner": "gov-integrations",
            "category": "government",
            "adapter": "integrations.government.HttpGovernmentAdapter",
            "environment": "per_authority",
            "mode": "production" if government else ("stub" if stubs else "disabled"),
            "configured": bool(government),
            "reliability": "circuit+retry",
            "security": "tls+api_key",
            "observability": "prometheus",
            "providers": sorted(government.keys()),
        },
        {
            "id": "notify.sms",
            "name": "SMS Notifications",
            "owner": "notifications",
            "category": "notifications",
            "adapter": "integrations.notifications.HttpSmsAdapter",
            "mode": "production" if sms.get("base_url") else "disabled",
            "configured": bool(sms.get("base_url")),
            "reliability": "retry",
            "security": "tls+api_key",
            "observability": "prometheus",
        },
        {
            "id": "notify.email",
            "name": "Email Notifications",
            "owner": "notifications",
            "category": "notifications",
            "adapter": "integrations.notifications.DjangoEmailAdapter",
            "mode": "production" if getattr(settings, "EMAIL_HOST", "") else ("console" if stubs else "disabled"),
            "configured": bool(getattr(settings, "EMAIL_HOST", "")),
            "reliability": "django_mail",
            "security": "smtp_tls",
            "observability": "django_logs",
        },
        {
            "id": "notify.push",
            "name": "Push Notifications",
            "owner": "notifications",
            "category": "notifications",
            "adapter": "integrations.notifications.HttpPushAdapter",
            "mode": "production" if push.get("base_url") else "disabled",
            "configured": bool(push.get("base_url")),
            "reliability": "retry",
            "security": "tls+api_key",
            "observability": "prometheus",
        },
        {
            "id": "docs.object_storage",
            "name": "Object Storage (S3-compatible)",
            "owner": "platform-storage",
            "category": "documents",
            "adapter": "integrations.storage.S3CompatibleStorage",
            "mode": "production" if storage.get("endpoint") else "disabled",
            "configured": bool(
                storage.get("endpoint") and storage.get("access_key") and storage.get("secret_key")
            ),
            "reliability": "http_timeout",
            "security": "sigv4+tls",
            "observability": "structured_logs",
        },
        {
            "id": "docs.malware_scan",
            "name": "Document Malware Scanner",
            "owner": "platform-security",
            "category": "documents",
            "adapter": "integrations.scanner.HttpDocumentScanner",
            "mode": "production" if (scanner.get("base_url") or getattr(settings, "MOBILITY_DOCUMENT_SCANNER", "")) else "disabled",
            "configured": bool(scanner.get("base_url") or getattr(settings, "MOBILITY_DOCUMENT_SCANNER", "")),
            "reliability": "fail_closed_prod",
            "security": "tls",
            "observability": "prometheus",
        },
        {
            "id": "maps.gis",
            "name": "Maps / Geocoding / Routing",
            "owner": "mobility-platform",
            "category": "gis",
            "adapter": "integrations.maps.HttpMapsAdapter",
            "mode": "production" if maps.get("base_url") else "disabled",
            "configured": bool(maps.get("base_url")),
            "reliability": "circuit+retry",
            "security": "tls+api_key",
            "observability": "prometheus",
        },
        {
            "id": "events.outbox_webhooks",
            "name": "Outbox Webhook Delivery",
            "owner": "enterprise-events",
            "category": "webhooks",
            "adapter": "enterprise.event_bus.deliver_outbox_row",
            "mode": "production" if outbox else ("noop_debug" if stubs else "disabled"),
            "configured": bool(outbox),
            "reliability": "retry+dlq_hooks",
            "security": "hmac_signature+tls",
            "observability": "prometheus+outbox_metrics",
        },
        {
            "id": "platform.stub_policy",
            "name": "Stub Adapter Policy",
            "owner": "platform-sre",
            "category": "policy",
            "adapter": "config.production_gates",
            "mode": "allow" if stubs else "deny",
            "configured": True,
            "detail": {"TAIFA_ALLOW_STUB_ADAPTERS": stubs},
        },
    ]
