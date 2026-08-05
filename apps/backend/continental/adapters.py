"""Identity federation adapters — national systems connect here, never hardcoded."""
from __future__ import annotations

from dataclasses import dataclass
from importlib import import_module
from typing import Protocol

from django.conf import settings

from .models import IdentityFederationBinding


@dataclass(frozen=True)
class IdentityLookupResult:
    provider: str
    matched: bool
    reference: str
    attributes: dict


class IdentityAdapter(Protocol):
    provider_code: str

    def lookup(self, *, identifier: str, identifier_type: str = "national_id") -> IdentityLookupResult: ...


class StubIdentityAdapter:
    def __init__(self, provider_code: str = "stub"):
        self.provider_code = provider_code

    def lookup(self, *, identifier: str, identifier_type: str = "national_id") -> IdentityLookupResult:
        masked = identifier[:2] + "***" if identifier else ""
        return IdentityLookupResult(
            provider=self.provider_code,
            matched=bool(identifier),
            reference=f"STUB-{self.provider_code}-{masked}",
            attributes={"identifier_type": identifier_type, "mode": "stub"},
        )


def _stubs_allowed() -> bool:
    return bool(getattr(settings, "TAIFA_ALLOW_STUB_ADAPTERS", True))


def resolve_identity_adapter(country_code: str, provider_code: str) -> IdentityAdapter:
    binding = IdentityFederationBinding.objects.filter(
        country__code=country_code.upper(),
        provider_code=provider_code,
        active=True,
    ).first()
    overrides = getattr(settings, "TAIFA_IDENTITY_ADAPTERS", None) or {}
    path = overrides.get(f"{country_code.upper()}.{provider_code}")
    if not path and binding:
        path = binding.adapter_path

    providers = getattr(settings, "TAIFA_IDENTITY_PROVIDERS", None) or {}
    provider_key = f"{country_code.upper()}.{provider_code}"
    if not path:
        if providers.get(provider_key) or providers.get(provider_code):
            path = "integrations.identity.HttpIdentityAdapter"
        elif _stubs_allowed():
            path = "continental.adapters.StubIdentityAdapter"
        else:
            raise RuntimeError(
                f"identity adapter for {provider_key} is not configured "
                "(set TAIFA_IDENTITY_ADAPTERS_JSON or TAIFA_IDENTITY_PROVIDERS_JSON)"
            )

    if "Stub" in path and not _stubs_allowed():
        raise RuntimeError(
            "stub identity adapters are forbidden in this environment "
            "(configure TAIFA_IDENTITY_ADAPTERS / TAIFA_IDENTITY_PROVIDERS)"
        )

    module_name, class_name = path.rsplit(".", 1)
    cls = getattr(import_module(module_name), class_name)
    try:
        if class_name == "HttpIdentityAdapter":
            adapter = cls(provider_code, country_code=country_code.upper())
        else:
            adapter = cls(provider_code)
    except TypeError:
        adapter = cls()

    # Normalize integrations.IdentityLookupResult → continental dataclass if needed
    if adapter.__class__.__module__.startswith("integrations."):
        original = adapter.lookup

        def _wrapped(*, identifier: str, identifier_type: str = "national_id") -> IdentityLookupResult:
            result = original(identifier=identifier, identifier_type=identifier_type)
            return IdentityLookupResult(
                provider=result.provider,
                matched=result.matched,
                reference=result.reference,
                attributes=dict(result.attributes),
            )

        adapter.lookup = _wrapped  # type: ignore[method-assign]
    return adapter
