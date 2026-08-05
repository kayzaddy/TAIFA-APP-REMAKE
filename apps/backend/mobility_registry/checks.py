from django.conf import settings
from django.core.checks import Error, register


@register()
def check_registry_security(app_configs, **kwargs):
    if settings.DEBUG or getattr(settings, "RUNNING_TESTS", False):
        return []
    errors = []
    keys = getattr(settings, "MOBILITY_DOCUMENT_KEYS", {}) or {}
    active = getattr(settings, "MOBILITY_ACTIVE_DOCUMENT_KEY_VERSION", "")
    if not keys or active not in keys:
        errors.append(
            Error(
                "Mobility Registry encryption keyring is not configured.",
                hint="Set MOBILITY_DOCUMENT_KEYS_JSON and MOBILITY_ACTIVE_DOCUMENT_KEY_VERSION.",
                id="mobility_registry.E001",
            )
        )
    if len(getattr(settings, "MOBILITY_PII_INDEX_KEY", "")) < 32:
        errors.append(
            Error(
                "MOBILITY_PII_INDEX_KEY must contain at least 32 characters.",
                id="mobility_registry.E002",
            )
        )
    if not getattr(settings, "MOBILITY_DOCUMENT_SCANNER", ""):
        errors.append(
            Error(
                "MOBILITY_DOCUMENT_SCANNER is required in production.",
                hint="Configure a fail-closed malware scanner implementing DocumentScanner.",
                id="mobility_registry.E003",
            )
        )
    return errors
