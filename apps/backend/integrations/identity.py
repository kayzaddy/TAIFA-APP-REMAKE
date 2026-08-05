"""National identity federation — HTTP production adapter (fail-closed)."""
from __future__ import annotations

from dataclasses import dataclass

from django.conf import settings

from .http_client import IntegrationHttpClient, IntegrationHttpError


@dataclass(frozen=True)
class IdentityLookupResult:
    provider: str
    matched: bool
    reference: str
    attributes: dict


class IdentityAdapterNotConfigured(RuntimeError):
    pass


class HttpIdentityAdapter:
    """Generic REST identity lookup.

    Configure per country.provider via TAIFA_IDENTITY_PROVIDERS_JSON:
      {"TZ.nida": {"base_url": "https://...", "api_key": "...", "lookup_path": "/v1/citizens/lookup"}}
    """

    def __init__(self, provider_code: str = "nida", *, country_code: str = "TZ"):
        self.provider_code = provider_code
        self.country_code = country_code.upper()
        key = f"{self.country_code}.{provider_code}"
        providers = getattr(settings, "TAIFA_IDENTITY_PROVIDERS", None) or {}
        cfg = providers.get(key) or providers.get(provider_code) or {}
        self._cfg = cfg
        base_url = (cfg.get("base_url") or "").strip()
        if not base_url:
            raise IdentityAdapterNotConfigured(
                f"identity provider {key} is not configured "
                "(set TAIFA_IDENTITY_PROVIDERS_JSON)"
            )
        headers = {"Accept": "application/json", "Content-Type": "application/json"}
        api_key = cfg.get("api_key") or cfg.get("token") or ""
        if api_key:
            scheme = cfg.get("auth_scheme", "Bearer")
            headers["Authorization"] = f"{scheme} {api_key}"
        self._client = IntegrationHttpClient(
            integration=f"identity.{key}",
            base_url=base_url,
            timeout_s=float(cfg.get("timeout_seconds", 15)),
            default_headers=headers,
            verify_tls=bool(cfg.get("verify_tls", True)),
        )
        self._lookup_path = cfg.get("lookup_path", "/v1/identity/lookup")

    def lookup(self, *, identifier: str, identifier_type: str = "national_id") -> IdentityLookupResult:
        try:
            resp = self._client.request(
                "POST",
                self._lookup_path,
                operation="lookup",
                json={
                    "identifier": identifier,
                    "identifier_type": identifier_type,
                    "country": self.country_code,
                    "provider": self.provider_code,
                },
            )
            data = resp.json() if resp.content else {}
        except IntegrationHttpError as exc:
            raise RuntimeError(f"identity lookup failed: {exc}") from exc
        return IdentityLookupResult(
            provider=self.provider_code,
            matched=bool(data.get("matched", data.get("found", False))),
            reference=str(data.get("reference") or data.get("id") or ""),
            attributes=dict(data.get("attributes") or data),
        )
