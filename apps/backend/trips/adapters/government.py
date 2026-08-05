"""Government / authority adapter interfaces for national mobility.

Concrete adapters are configured via settings MOBILITY_GOVERNMENT_ADAPTERS
and TAIFA_GOVERNMENT_PROVIDERS — never hardcoded call sites.
"""
from __future__ import annotations

from dataclasses import dataclass
from importlib import import_module
from typing import Protocol

from django.conf import settings


@dataclass(frozen=True)
class GovernmentReportResult:
    authority: str
    accepted: bool
    reference: str
    payload: dict


class GovernmentReportingAdapter(Protocol):
    authority_code: str

    def submit_transport_statistics(self, *, period_start: str, period_end: str, payload: dict) -> GovernmentReportResult: ...


class StubGovernmentAdapter:
    """Dev/test default only — refused when TAIFA_ALLOW_STUB_ADAPTERS is false."""

    def __init__(self, authority_code: str):
        self.authority_code = authority_code

    def submit_transport_statistics(self, *, period_start: str, period_end: str, payload: dict) -> GovernmentReportResult:
        return GovernmentReportResult(
            authority=self.authority_code,
            accepted=True,
            reference=f"STUB-{self.authority_code}-{period_start}-{period_end}",
            payload={"echo": payload, "mode": "stub"},
        )


class LatraAdapter(StubGovernmentAdapter):
    def __init__(self):
        super().__init__("LATRA")


class TanroadsAdapter(StubGovernmentAdapter):
    def __init__(self):
        super().__init__("TANROADS")


class TaruraAdapter(StubGovernmentAdapter):
    def __init__(self):
        super().__init__("TARURA")


class LgaAdapter(StubGovernmentAdapter):
    def __init__(self):
        super().__init__("LGA")


class TraAdapter(StubGovernmentAdapter):
    def __init__(self):
        super().__init__("TRA")


class PoliceAdapter(StubGovernmentAdapter):
    def __init__(self):
        super().__init__("POLICE")


class EmergencyServicesAdapter(StubGovernmentAdapter):
    def __init__(self):
        super().__init__("EMERGENCY")


class NidaAdapter(StubGovernmentAdapter):
    def __init__(self):
        super().__init__("NIDA")


class BrelaAdapter(StubGovernmentAdapter):
    def __init__(self):
        super().__init__("BRELA")


class TrafficManagementAdapter(StubGovernmentAdapter):
    def __init__(self):
        super().__init__("TRAFFIC")


DEFAULT_STUB_ADAPTERS = {
    "LATRA": "trips.adapters.government.LatraAdapter",
    "TANROADS": "trips.adapters.government.TanroadsAdapter",
    "TARURA": "trips.adapters.government.TaruraAdapter",
    "LGA": "trips.adapters.government.LgaAdapter",
    "TRA": "trips.adapters.government.TraAdapter",
    "POLICE": "trips.adapters.government.PoliceAdapter",
    "EMERGENCY": "trips.adapters.government.EmergencyServicesAdapter",
    "NIDA": "trips.adapters.government.NidaAdapter",
    "BRELA": "trips.adapters.government.BrelaAdapter",
    "TRAFFIC": "trips.adapters.government.TrafficManagementAdapter",
}

DEFAULT_HTTP_ADAPTERS = {
    "LATRA": "integrations.government.LatraHttpAdapter",
    "TANROADS": "integrations.government.TanroadsHttpAdapter",
    "TARURA": "integrations.government.TaruraHttpAdapter",
    "LGA": "integrations.government.LgaHttpAdapter",
    "TRA": "integrations.government.TraHttpAdapter",
    "POLICE": "integrations.government.PoliceHttpAdapter",
    "EMERGENCY": "integrations.government.EmergencyHttpAdapter",
    "NIDA": "integrations.government.NidaHttpAdapter",
    "BRELA": "integrations.government.BrelaHttpAdapter",
    "TRAFFIC": "integrations.government.TrafficHttpAdapter",
}


def _stubs_allowed() -> bool:
    return bool(getattr(settings, "TAIFA_ALLOW_STUB_ADAPTERS", True))


def government_adapter(authority: str) -> GovernmentReportingAdapter:
    code = authority.upper()
    mapping = getattr(settings, "MOBILITY_GOVERNMENT_ADAPTERS", None) or {}
    providers = getattr(settings, "TAIFA_GOVERNMENT_PROVIDERS", None) or {}
    path = mapping.get(code)

    if not path:
        if providers.get(code):
            path = DEFAULT_HTTP_ADAPTERS.get(code, "integrations.government.HttpGovernmentAdapter")
        elif _stubs_allowed():
            path = DEFAULT_STUB_ADAPTERS.get(code, "trips.adapters.government.StubGovernmentAdapter")
        else:
            raise RuntimeError(
                f"government adapter for {code} is not configured "
                "(set MOBILITY_GOVERNMENT_ADAPTERS_JSON or TAIFA_GOVERNMENT_PROVIDERS_JSON)"
            )

    if "Stub" in path and not _stubs_allowed():
        raise RuntimeError(
            f"stub government adapters are forbidden in this environment ({code})"
        )

    module_name, class_name = path.rsplit(".", 1)
    cls = getattr(import_module(module_name), class_name)
    try:
        adapter = cls()
    except TypeError:
        adapter = cls(code)

    # Normalize integrations result → local dataclass
    if adapter.__class__.__module__.startswith("integrations."):
        original = adapter.submit_transport_statistics

        def _wrapped(*, period_start: str, period_end: str, payload: dict) -> GovernmentReportResult:
            result = original(period_start=period_start, period_end=period_end, payload=payload)
            return GovernmentReportResult(
                authority=result.authority,
                accepted=result.accepted,
                reference=result.reference,
                payload=dict(result.payload),
            )

        adapter.submit_transport_statistics = _wrapped  # type: ignore[method-assign]
    return adapter
