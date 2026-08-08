"""Django settings for the TAIFA payment service.

Configuration is environment-driven (12-factor). A local `.env` is loaded if
present. The database defaults to Postgres via `DATABASE_URL`; tests fall back
to SQLite so the suite runs without a running Postgres.

Security posture, CORS, throttling, API schema, logging and error tracking are
all configured here and toggle on real environment signals — nothing is a
placeholder: with `DJANGO_DEBUG=false` the service serves over HTTPS-only
cookies, HSTS, and locked-down hosts/origins.
"""
from __future__ import annotations

import os
import sys
import json
import base64
from pathlib import Path

import dj_database_url
from dotenv import load_dotenv

RUNNING_TESTS = "test" in sys.argv or "PYTEST_CURRENT_TEST" in os.environ

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / ".env")


def _env_bool(key: str, default: bool = False) -> bool:
    return os.environ.get(key, str(default)).lower() in {"1", "true", "yes", "on"}


def _env_list(key: str, default: str = "") -> list[str]:
    raw = os.environ.get(key, default)
    return [item.strip() for item in raw.split(",") if item.strip()]


SECRET_KEY = os.environ.get("DJANGO_SECRET_KEY", "dev-insecure-change-me")
DEBUG = _env_bool("DJANGO_DEBUG", True)
ALLOWED_HOSTS = _env_list("DJANGO_ALLOWED_HOSTS", "*" if DEBUG else "")

INSTALLED_APPS = [
    "daphne",
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "rest_framework",
    "drf_spectacular",
    "corsheaders",
    "channels",
    "payments.apps.PaymentsConfig",
    "enterprise.apps.EnterpriseConfig",
    "mobility_registry.apps.MobilityRegistryConfig",
    "trips",
    "commerce",
    "tourism",
    "ecosystem.apps.EcosystemConfig",
    "ai_os.apps.AiOsConfig",
    "continental.apps.ContinentalConfig",
    "governance.apps.GovernanceConfig",
    "integrations.apps.IntegrationsConfig",
    "winga.apps.WingaConfig",
    "winga_property.apps.WingaPropertyConfig",
    "mos.apps.MosConfig",
    "acceptance.apps.AcceptanceConfig",
    "express.apps.ExpressConfig",
    "mobility_channels.apps.MobilityChannelsConfig",
    "taifa_merchant.apps.TaifaMerchantConfig",
]

MIDDLEWARE = [
    "corsheaders.middleware.CorsMiddleware",
    "django.middleware.security.SecurityMiddleware",
    "config.middleware.RequestIDMiddleware",
    "config.middleware.HttpMetricsMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

SERVICE_NAME = os.environ.get("OTEL_SERVICE_NAME", "taifa-payments")
ENVIRONMENT_NAME = os.environ.get(
    "TAIFA_ENVIRONMENT",
    os.environ.get("SENTRY_ENVIRONMENT", "development" if DEBUG else "production"),
)

ROOT_URLCONF = "config.urls"
WSGI_APPLICATION = "config.wsgi.application"
ASGI_APPLICATION = "config.asgi.application"

if DEBUG or RUNNING_TESTS:
    CHANNEL_LAYERS = {
        "default": {"BACKEND": "channels.layers.InMemoryChannelLayer"},
    }
else:
    CHANNEL_LAYERS = {
        "default": {
            "BACKEND": "channels_redis.core.RedisChannelLayer",
            "CONFIG": {
                "hosts": [
                    os.environ.get(
                        "CHANNEL_REDIS_URL",
                        os.environ.get("CELERY_BROKER_URL", "redis://localhost:6379/0"),
                    )
                ],
                "capacity": int(os.environ.get("CHANNEL_CAPACITY", "1500")),
                "expiry": int(os.environ.get("CHANNEL_EXPIRY_SECONDS", "60")),
            },
        },
    }

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

# Postgres in every real environment; SQLite only as a test/dev fallback.
DATABASES = {
    "default": dj_database_url.parse(
        os.environ.get("DATABASE_URL", f"sqlite:///{BASE_DIR / 'db.sqlite3'}"),
        conn_max_age=600,
    )
}

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
]

LANGUAGE_CODE = "en-us"
TIME_ZONE = "Africa/Dar_es_Salaam"
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

# === Django REST Framework ===
REST_FRAMEWORK = {
    "DEFAULT_RENDERER_CLASSES": ["rest_framework.renderers.JSONRenderer"],
    "DEFAULT_PARSER_CLASSES": ["rest_framework.parsers.JSONParser"],
    "DEFAULT_AUTHENTICATION_CLASSES": ["payments.auth.DeviceTokenAuthentication"],
    # Default deny: views that are intentionally open must set AllowAny explicitly
    # (e.g. device register, health probes via non-DRF routes).
    "DEFAULT_PERMISSION_CLASSES": ["payments.auth.IsDevice"],
    "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
    # Abuse protection. Registration is a sensitive open endpoint, so it gets a
    # dedicated, tighter scope on top of the anon default.
    "DEFAULT_THROTTLE_CLASSES": [
        "rest_framework.throttling.AnonRateThrottle",
        "rest_framework.throttling.ScopedRateThrottle",
    ],
    "DEFAULT_THROTTLE_RATES": {
        "anon": os.environ.get("THROTTLE_ANON", "120/min"),
        "device_register": os.environ.get("THROTTLE_DEVICE_REGISTER", "20/min"),
        "money_write": os.environ.get("THROTTLE_MONEY_WRITE", "60/min"),
    },
}

# Throttling needs a cache. LocMem is per-process (fine for dev/tests); point
# CACHE_URL at Redis in production for a shared limiter.
_cache_url = os.environ.get("CACHE_URL", "").strip()
if _cache_url and not RUNNING_TESTS:
    CACHES = {
        "default": {
            "BACKEND": "django.core.cache.backends.redis.RedisCache",
            "LOCATION": _cache_url,
        }
    }
else:
    CACHES = {
        "default": {
            "BACKEND": "django.core.cache.backends.locmem.LocMemCache",
            "LOCATION": "taifa-throttle",
        }
    }
# Tests must not trip the limiter; disable throttling under the test runner.
if _env_bool("DISABLE_THROTTLING", False) or RUNNING_TESTS:
    REST_FRAMEWORK["DEFAULT_THROTTLE_RATES"] = {k: None for k in REST_FRAMEWORK["DEFAULT_THROTTLE_RATES"]}

SPECTACULAR_SETTINGS = {
    "TITLE": "TAIFA Platform API",
    "DESCRIPTION": (
        "Authoritative TAIFA Platform APIs for identity-bound access, payments "
        "over the double-entry ledger, enterprise financial operations, commerce "
        "and national mobility."
    ),
    "VERSION": "1.0.0",
    "SERVE_INCLUDE_SCHEMA": False,
    "SERVERS": [{"url": "/", "description": "current host"}],
    "ENUM_NAME_OVERRIDES": {
        "MobilityTransportModeEnum": "trips.models.TransportMode.choices",
        "MobilityVerificationStatusEnum": "trips.models.VerificationStatus.choices",
        "MobilityFleetTypeEnum": "trips.models.FleetType.choices",
        "MobilityDriverStatusEnum": "trips.models.DriverStatus.choices",
        "MobilityDriverAvailabilityEnum": "trips.models.DriverAvailability.choices",
        "MobilityVehicleStatusEnum": "trips.models.VehicleStatus.choices",
        "MobilityTripStatusEnum": "trips.models.TripStatus.choices",
        "MobilityTripKindEnum": "trips.models.TripKind.choices",
        "MobilityDispatchStrategyEnum": "trips.models.DispatchStrategy.choices",
        "MobilityDispatchOfferStatusEnum": "trips.models.DispatchOfferStatus.choices",
        "MobilitySafetyStatusEnum": "trips.models.SafetyIncidentStatus.choices",
        "PaymentLinkStatusEnum": "payments.models.PaymentLinkStatus.choices",
        "MoneyRequestStatusEnum": "payments.models.MoneyRequestStatus.choices",
    },
    "TAGS": [
        {"name": "auth", "description": "Device registration + bound tokens"},
        {"name": "wallet", "description": "Balance + transaction reads"},
        {"name": "payments", "description": "Top-ups and transfers"},
        {"name": "social-payments", "description": "Payment links, money requests, QR, contacts"},
        {"name": "webhooks", "description": "Provider callbacks"},
        {"name": "commerce", "description": "Food / stay / flight / tour bookings"},
        {"name": "tourism", "description": "DTOS trips and itineraries"},
        {"name": "mos", "description": "Taifa Commerce Merchant Operating System"},
        {"name": "map", "description": "Taifa Merchant Acceptance Platform (QR, links, invoices, POS)"},
        {"name": "trips", "description": "Mobility trip records"},
        {"name": "platform", "description": "Digital ecosystem catalog and Super App modules"},
        {"name": "platform-ai", "description": "Shared AI capability contracts"},
        {"name": "platform-workflow", "description": "Ecosystem workflow bindings"},
        {"name": "platform-open", "description": "Open platform partners and webhooks"},
        {"name": "platform-agriculture", "description": "Agriculture domain APIs"},
        {"name": "ai-os", "description": "Taifa AI Operating System"},
        {"name": "continental", "description": "Pan-African multi-country platform"},
        {"name": "continental-fx", "description": "FX quotes and conversion"},
        {"name": "governance", "description": "Enterprise governance scorecard"},
    ],
}

# === Security (production hardening; relaxed only when DEBUG) ===
CORS_ALLOW_ALL_ORIGINS = _env_bool("CORS_ALLOW_ALL", DEBUG)
CORS_ALLOWED_ORIGINS = _env_list("CORS_ALLOWED_ORIGINS")
CSRF_TRUSTED_ORIGINS = _env_list("CSRF_TRUSTED_ORIGINS")

if not DEBUG:
    SECURE_SSL_REDIRECT = _env_bool("SECURE_SSL_REDIRECT", True)
    SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
    SECURE_HSTS_SECONDS = int(os.environ.get("SECURE_HSTS_SECONDS", "31536000"))
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    X_FRAME_OPTIONS = "DENY"

# === Celery ===
CELERY_BROKER_URL = os.environ.get("CELERY_BROKER_URL", "redis://localhost:6379/0")
CELERY_RESULT_BACKEND = os.environ.get("CELERY_RESULT_BACKEND", "redis://localhost:6379/1")
# Run tasks synchronously unless a real worker is configured (keeps dev/tests simple).
CELERY_TASK_ALWAYS_EAGER = _env_bool("CELERY_TASK_ALWAYS_EAGER", True)
CELERY_TASK_EAGER_PROPAGATES = True
# Celery Beat: daily ledger reconciliation (requires a beat process in production).
CELERY_BEAT_SCHEDULE = {
    "reconcile-ledger-daily": {
        "task": "payments.reconcile_ledger",
        "schedule": 60 * 60 * 24,  # every 24h
    },
    "ops-heartbeat-hourly": {
        "task": "payments.ops_heartbeat",
        "schedule": 60 * 60,
    },
    "run-due-recurring-payments": {
        "task": "payments.run_due_recurring_payments",
        "schedule": 60 * 5,  # every 5 minutes
    },
    "mobility-scheduled-dispatch": {
        "task": "mobility.dispatch_scheduled",
        "schedule": 30,
    },
    "mobility-expire-offers": {
        "task": "mobility.expire_dispatch_offers",
        "schedule": 15,
    },
    "mobility-daily-projections": {
        "task": "mobility.build_daily_metrics",
        "schedule": 60 * 60 * 24,
    },
    "mobility-driver-performance-refresh": {
        "task": "mobility.refresh_driver_performance",
        "schedule": 60 * 60,
    },
    "mobility-materialize-recurring-rides": {
        "task": "mobility.materialize_recurring_rides",
        "schedule": 60 * 15,
    },
    "mobility-national-daily-metrics": {
        "task": "mobility.build_national_daily_metrics",
        "schedule": 60 * 60 * 24,
    },
    "mobility-registry-expiry-monitor": {
        "task": "mobility_registry.monitor_expiry",
        "schedule": 60 * 60 * 24,
    },
    "mobility-registry-notification-publisher": {
        "task": "mobility_registry.publish_notifications",
        "schedule": 30,
    },
    "enterprise-drain-outbox": {
        "task": "enterprise.drain_outbox",
        "schedule": 15,
    },
}

# === Logging (structured JSON in production; request/trace correlated) ===
LOG_LEVEL = os.environ.get("DJANGO_LOG_LEVEL", "INFO")
LOG_JSON = _env_bool("TAIFA_LOG_JSON", not DEBUG and not RUNNING_TESTS)
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "filters": {
        "request_id": {"()": "config.middleware.RequestIDLogFilter"},
    },
    "formatters": {
        "verbose": {
            "format": "%(levelname)s %(asctime)s [%(request_id)s] %(name)s %(message)s",
        },
        "json": {
            "()": "config.logging_json.JsonLogFormatter",
        },
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "filters": ["request_id"],
            "formatter": "json" if LOG_JSON else "verbose",
        },
    },
    "root": {"handlers": ["console"], "level": LOG_LEVEL},
    "loggers": {
        "django.request": {"handlers": ["console"], "level": "WARNING", "propagate": False},
        "payments": {"handlers": ["console"], "level": LOG_LEVEL, "propagate": False},
        "config": {"handlers": ["console"], "level": LOG_LEVEL, "propagate": False},
    },
}

# === OpenTelemetry (opt-in via OTEL_EXPORTER_OTLP_ENDPOINT) ===
if not RUNNING_TESTS:
    try:
        from config.otel import setup_tracing

        setup_tracing()
    except Exception:  # pragma: no cover
        pass

# === Error tracking / APM (opt-in via SENTRY_DSN) ===
SENTRY_DSN = os.environ.get("SENTRY_DSN", "")
if SENTRY_DSN:
    import sentry_sdk
    from sentry_sdk.integrations.celery import CeleryIntegration
    from sentry_sdk.integrations.django import DjangoIntegration

    sentry_sdk.init(
        dsn=SENTRY_DSN,
        integrations=[DjangoIntegration(), CeleryIntegration()],
        traces_sample_rate=float(os.environ.get("SENTRY_TRACES_SAMPLE_RATE", "0.1")),
        send_default_pii=False,
        environment=os.environ.get("SENTRY_ENVIRONMENT", ENVIRONMENT_NAME),
    )

# === M-Pesa (Safaricom/Vodacom Daraja) ===
# Sandbox Lipa Na M-Pesa Online defaults (Safaricom-published shortcode + passkey).
# Production MUST set MPESA_PASSKEY explicitly — never rely on the sandbox default.
_MPESA_ENV = os.environ.get("MPESA_ENVIRONMENT", "sandbox")
_MPESA_SANDBOX_PASSKEY = "bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919"
_mpesa_passkey = os.environ.get("MPESA_PASSKEY", "")
if not _mpesa_passkey and _MPESA_ENV == "sandbox":
    _mpesa_passkey = _MPESA_SANDBOX_PASSKEY

MPESA = {
    "ENVIRONMENT": _MPESA_ENV,  # sandbox | production
    "CONSUMER_KEY": os.environ.get("MPESA_CONSUMER_KEY", ""),
    "CONSUMER_SECRET": os.environ.get("MPESA_CONSUMER_SECRET", ""),
    "SHORTCODE": os.environ.get("MPESA_SHORTCODE", "174379"),
    "PASSKEY": _mpesa_passkey,
    "INITIATOR_NAME": os.environ.get("MPESA_INITIATOR_NAME", ""),
    "SECURITY_CREDENTIAL": os.environ.get("MPESA_SECURITY_CREDENTIAL", ""),
    "CALLBACK_BASE_URL": os.environ.get("MPESA_CALLBACK_BASE_URL", "https://example.com"),
    "TIMEOUT_SECONDS": int(os.environ.get("MPESA_TIMEOUT_SECONDS", "30")),
}

# Webhook trust — production (DEBUG=false) requires shared secret via system check.
# HMAC: X-TAIFA-Webhook-Timestamp + X-TAIFA-Webhook-Signature (hex hmac-sha256).
MPESA_WEBHOOK_ALLOWED_IPS = _env_list("MPESA_WEBHOOK_ALLOWED_IPS", "")
MPESA_WEBHOOK_SHARED_SECRET = os.environ.get("MPESA_WEBHOOK_SHARED_SECRET", "")
MPESA_WEBHOOK_REQUIRE_HMAC = _env_bool("MPESA_WEBHOOK_REQUIRE_HMAC", not DEBUG and not RUNNING_TESTS)
MPESA_WEBHOOK_MAX_SKEW_SECONDS = int(os.environ.get("MPESA_WEBHOOK_MAX_SKEW_SECONDS", "300") or 300)
MPESA_WEBHOOK_FAIL_CLOSED = _env_bool("MPESA_WEBHOOK_FAIL_CLOSED", not DEBUG and not RUNNING_TESTS)

# Prometheus scrape endpoint (`GET /metrics`). Empty allow-list = open (typical
# for private k8s/compose networks). Restrict in public deployments.
METRICS_ALLOWED_IPS = _env_list("METRICS_ALLOWED_IPS", "")

# Demo money paths — default ON only in DEBUG; always OFF in production (system check).
ALLOW_DEMO_STK = _env_bool("TAIFA_ALLOW_DEMO_STK", DEBUG)
ALLOW_DEMO_WALLET_FUNDING = _env_bool("TAIFA_ALLOW_DEMO_WALLET_FUNDING", DEBUG)
WITHDRAWAL_AUTO_APPROVE = _env_bool("TAIFA_WITHDRAWAL_AUTO_APPROVE", DEBUG)

# Platform cut on payment links owned by a self-service merchant (basis
# points; 150 = 1.5%). Snapshotted onto each PaymentLink at creation — see
# payments.models.PaymentLink.fee_bps. Person-to-person (send/request/split)
# is always free regardless of this setting.
PAYMENTS_MERCHANT_FEE_BPS = int(os.environ.get("PAYMENTS_MERCHANT_FEE_BPS", "150"))
REQUIRE_DEVICE_BINDING = _env_bool("TAIFA_REQUIRE_DEVICE_BINDING", not DEBUG)

# National Mobility Registry encryption keyring. Production requires explicit,
# independently managed values; deterministic dev/test keys never cross that gate.
_registry_dev_key = base64.b64encode(b"taifa-registry-dev-key-32-byte!!").decode()
MOBILITY_DOCUMENT_KEYS = json.loads(
    os.environ.get(
        "MOBILITY_DOCUMENT_KEYS_JSON",
        json.dumps({"dev-v1": _registry_dev_key}) if (DEBUG or RUNNING_TESTS) else "{}",
    )
)
MOBILITY_ACTIVE_DOCUMENT_KEY_VERSION = os.environ.get(
    "MOBILITY_ACTIVE_DOCUMENT_KEY_VERSION",
    "dev-v1" if (DEBUG or RUNNING_TESTS) else "",
)
MOBILITY_PII_INDEX_KEY = os.environ.get(
    "MOBILITY_PII_INDEX_KEY",
    "taifa-registry-dev-index-key-change-me" if (DEBUG or RUNNING_TESTS) else "",
)
MOBILITY_VERIFICATION_ADAPTERS = json.loads(
    os.environ.get("MOBILITY_VERIFICATION_ADAPTERS_JSON", "{}")
)
MOBILITY_GOVERNMENT_ADAPTERS = json.loads(
    os.environ.get("MOBILITY_GOVERNMENT_ADAPTERS_JSON", "{}")
)
MOBILITY_DOCUMENT_SCANNER = os.environ.get("MOBILITY_DOCUMENT_SCANNER", "")

# === Risk Engine ===
# Production defaults are FINITE. Unlimited requires RISK_ALLOW_UNLIMITED=true.
# Minor units: TZS has 2 decimals → 5_000_000 TZS = 500_000_000 minor.
_RISK_PROD = not DEBUG and not RUNNING_TESTS
RISK_ALLOW_UNLIMITED = _env_bool("RISK_ALLOW_UNLIMITED", False)
RISK_PER_TXN_LIMIT_MINOR = int(
    os.environ.get(
        "RISK_PER_TXN_LIMIT_MINOR",
        "0" if (DEBUG or RUNNING_TESTS) else str(500_000_000),
    )
    or 0
)
RISK_DAILY_DEBIT_LIMIT_MINOR = int(
    os.environ.get(
        "RISK_DAILY_DEBIT_LIMIT_MINOR",
        "0" if (DEBUG or RUNNING_TESTS) else str(2_000_000_000),
    )
    or 0
)
RISK_DAILY_CREDIT_LIMIT_MINOR = int(
    os.environ.get(
        "RISK_DAILY_CREDIT_LIMIT_MINOR",
        "0" if (DEBUG or RUNNING_TESTS) else str(5_000_000_000),
    )
    or 0
)
RISK_REVIEW_ABOVE_MINOR = int(
    os.environ.get(
        "RISK_REVIEW_ABOVE_MINOR",
        "0" if (DEBUG or RUNNING_TESTS) else str(100_000_000),
    )
    or 0
)
RISK_VELOCITY_WINDOW_SECONDS = int(os.environ.get("RISK_VELOCITY_WINDOW_SECONDS", "60") or 60)
RISK_VELOCITY_MAX_TXNS = int(os.environ.get("RISK_VELOCITY_MAX_TXNS", "30") or 30)
RISK_SANCTIONS_OWNERS = _env_list("RISK_SANCTIONS_OWNERS", "")

# Anti-abuse (not a money-movement limit, so always finite — no DEBUG/test
# carve-out): caps unsolicited MoneyRequests (incl. one-per-participant on a
# BillSplit) so a stranger can't flood someone's inbox with requests.
RISK_MAX_PENDING_REQUESTS_PER_PAYER = int(
    os.environ.get("RISK_MAX_PENDING_REQUESTS_PER_PAYER", "10") or 0
)
RISK_MAX_PENDING_REQUESTS_TOTAL = int(
    os.environ.get("RISK_MAX_PENDING_REQUESTS_TOTAL", "100") or 0
)

# Ecosystem AI adapters: capability_code → dotted class path (optional overrides)
TAIFA_AI_ADAPTERS = json.loads(os.environ.get("TAIFA_AI_ADAPTERS_JSON", "{}"))
# AI OS model adapters: model_code → dotted class path
TAIFA_AI_OS_ADAPTERS = json.loads(os.environ.get("TAIFA_AI_OS_ADAPTERS_JSON", "{}"))
# Identity federation: "TZ.nida" → adapter class path
TAIFA_IDENTITY_ADAPTERS = json.loads(os.environ.get("TAIFA_IDENTITY_ADAPTERS_JSON", "{}"))
# When false (required in production), Stub* AI/identity/gov adapters are refused.
TAIFA_ALLOW_STUB_ADAPTERS = _env_bool(
    "TAIFA_ALLOW_STUB_ADAPTERS",
    default=DEBUG or RUNNING_TESTS,
)
# Outbox webhook fan-out: JSON list of {"url": "...", "secret": "..."} or bare URLs.
TAIFA_OUTBOX_WEBHOOK_URLS = json.loads(os.environ.get("TAIFA_OUTBOX_WEBHOOK_URLS_JSON", "[]"))
TAIFA_OUTBOX_WEBHOOK_SECRET = os.environ.get("TAIFA_OUTBOX_WEBHOOK_SECRET", "")

# === Production integration providers (fail-closed when stubs disallowed) ===
TAIFA_INTEGRATION_TIMEOUT_SECONDS = float(os.environ.get("TAIFA_INTEGRATION_TIMEOUT_SECONDS", "15"))
TAIFA_INTEGRATION_MAX_RETRIES = int(os.environ.get("TAIFA_INTEGRATION_MAX_RETRIES", "3") or 3)
TAIFA_IDENTITY_PROVIDERS = json.loads(os.environ.get("TAIFA_IDENTITY_PROVIDERS_JSON", "{}"))
TAIFA_GOVERNMENT_PROVIDERS = json.loads(os.environ.get("TAIFA_GOVERNMENT_PROVIDERS_JSON", "{}"))
TAIFA_AI_PROVIDER = json.loads(os.environ.get("TAIFA_AI_PROVIDER_JSON", "{}"))
TAIFA_SMS_PROVIDER = json.loads(os.environ.get("TAIFA_SMS_PROVIDER_JSON", "{}"))
TAIFA_PUSH_PROVIDER = json.loads(os.environ.get("TAIFA_PUSH_PROVIDER_JSON", "{}"))
TAIFA_MAPS_PROVIDER = json.loads(os.environ.get("TAIFA_MAPS_PROVIDER_JSON", "{}"))
TAIFA_OBJECT_STORAGE = json.loads(os.environ.get("TAIFA_OBJECT_STORAGE_JSON", "{}"))
TAIFA_DOCUMENT_SCANNER = json.loads(os.environ.get("TAIFA_DOCUMENT_SCANNER_JSON", "{}"))

AIRTEL_MONEY = {
    "CLIENT_ID": os.environ.get("AIRTEL_CLIENT_ID", ""),
    "CLIENT_SECRET": os.environ.get("AIRTEL_CLIENT_SECRET", ""),
    "BASE_URL": os.environ.get(
        "AIRTEL_BASE_URL",
        "https://openapiuat.airtel.africa",
    ),
    "COUNTRY": os.environ.get("AIRTEL_COUNTRY", "TZ"),
    "CURRENCY": os.environ.get("AIRTEL_CURRENCY", "TZS"),
    "TIMEOUT_SECONDS": int(os.environ.get("AIRTEL_TIMEOUT_SECONDS", "30") or 30),
}
SELCOM = {
    "BASE_URL": os.environ.get("SELCOM_BASE_URL", "https://apigw.selcommobile.com"),
    "API_KEY": os.environ.get("SELCOM_API_KEY", ""),
    "API_SECRET": os.environ.get("SELCOM_API_SECRET", ""),
    "VENDOR": os.environ.get("SELCOM_VENDOR", ""),
    "REDIRECT_URL": os.environ.get("SELCOM_REDIRECT_URL", "https://taifa.app/pay/return"),
    "CANCEL_URL": os.environ.get("SELCOM_CANCEL_URL", "https://taifa.app/pay/cancel"),
    "WEBHOOK_URL": os.environ.get("SELCOM_WEBHOOK_URL", ""),
    "TIMEOUT_SECONDS": int(os.environ.get("SELCOM_TIMEOUT_SECONDS", "30") or 30),
}
CARD_ACQUIRER = {
    "BASE_URL": os.environ.get("CARD_ACQUIRER_BASE_URL", ""),
    "API_KEY": os.environ.get("CARD_ACQUIRER_API_KEY", ""),
    "MERCHANT_ID": os.environ.get("CARD_ACQUIRER_MERCHANT_ID", ""),
    "TIMEOUT_SECONDS": int(os.environ.get("CARD_ACQUIRER_TIMEOUT_SECONDS", "30") or 30),
}

# === Taifa Merchant App (BFF) ===
MERCHANT_JWT_SECRET = os.environ.get("MERCHANT_JWT_SECRET", SECRET_KEY)
MERCHANT_JWT_ISSUER = os.environ.get("MERCHANT_JWT_ISSUER", "taifa-identity")
MERCHANT_JWT_AUDIENCE = os.environ.get("MERCHANT_JWT_AUDIENCE", "taifa-merchant")
MERCHANT_JWT_TTL_SECONDS = int(os.environ.get("MERCHANT_JWT_TTL_SECONDS", "3600"))
MERCHANT_AUTH_PEPPER = os.environ.get("MERCHANT_AUTH_PEPPER", "change-me-merchant-pepper")
TAIFA_IDENTITY_JWKS_URL = os.environ.get("TAIFA_IDENTITY_JWKS_URL", "")
