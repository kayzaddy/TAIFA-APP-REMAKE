"""Government / authority HTTP adapters — configurable, never hardcoded providers."""
from __future__ import annotations

from dataclasses import dataclass

from django.conf import settings

from .http_client import IntegrationHttpClient, IntegrationHttpError


@dataclass(frozen=True)
class GovernmentReportResult:
    authority: str
    accepted: bool
    reference: str
    payload: dict


class GovernmentAdapterNotConfigured(RuntimeError):
    pass


class HttpGovernmentAdapter:
    """POST transport statistics / filings to a configured authority endpoint.

    TAIFA_GOVERNMENT_PROVIDERS_JSON example:
      {
        "LATRA": {
          "base_url": "https://api.latra.go.tz",
          "api_key": "...",
          "submit_path": "/v1/mobility/statistics",
          "timeout_seconds": 20
        }
      }
    """

    def __init__(self, authority_code: str = "LATRA"):
        self.authority_code = authority_code.upper()
        providers = getattr(settings, "TAIFA_GOVERNMENT_PROVIDERS", None) or {}
        cfg = providers.get(self.authority_code) or {}
        base_url = (cfg.get("base_url") or "").strip()
        if not base_url:
            raise GovernmentAdapterNotConfigured(
                f"government provider {self.authority_code} is not configured "
                "(set TAIFA_GOVERNMENT_PROVIDERS_JSON)"
            )
        headers = {"Accept": "application/json", "Content-Type": "application/json"}
        api_key = cfg.get("api_key") or cfg.get("token") or ""
        if api_key:
            scheme = cfg.get("auth_scheme", "Bearer")
            headers["Authorization"] = f"{scheme} {api_key}"
        for k, v in (cfg.get("extra_headers") or {}).items():
            headers[str(k)] = str(v)
        self._client = IntegrationHttpClient(
            integration=f"government.{self.authority_code}",
            base_url=base_url,
            timeout_s=float(cfg.get("timeout_seconds", 20)),
            default_headers=headers,
            verify_tls=bool(cfg.get("verify_tls", True)),
        )
        self._submit_path = cfg.get("submit_path", "/v1/reports")

    def submit_transport_statistics(
        self, *, period_start: str, period_end: str, payload: dict
    ) -> GovernmentReportResult:
        body = {
            "authority": self.authority_code,
            "period_start": period_start,
            "period_end": period_end,
            "payload": payload,
        }
        try:
            resp = self._client.request(
                "POST",
                self._submit_path,
                operation="submit_statistics",
                json=body,
            )
            data = resp.json() if resp.content else {}
        except IntegrationHttpError as exc:
            return GovernmentReportResult(
                authority=self.authority_code,
                accepted=False,
                reference="",
                payload={"error": str(exc), "status_code": exc.status_code},
            )
        return GovernmentReportResult(
            authority=self.authority_code,
            accepted=bool(data.get("accepted", True)),
            reference=str(data.get("reference") or data.get("id") or resp.headers.get("X-Request-Id", "")),
            payload=data if isinstance(data, dict) else {"raw": data},
        )


# Thin authority aliases — all delegate to the same configurable HTTP adapter.
class LatraHttpAdapter(HttpGovernmentAdapter):
    def __init__(self):
        super().__init__("LATRA")


class TanroadsHttpAdapter(HttpGovernmentAdapter):
    def __init__(self):
        super().__init__("TANROADS")


class TaruraHttpAdapter(HttpGovernmentAdapter):
    def __init__(self):
        super().__init__("TARURA")


class LgaHttpAdapter(HttpGovernmentAdapter):
    def __init__(self):
        super().__init__("LGA")


class TraHttpAdapter(HttpGovernmentAdapter):
    def __init__(self):
        super().__init__("TRA")


class PoliceHttpAdapter(HttpGovernmentAdapter):
    def __init__(self):
        super().__init__("POLICE")


class EmergencyHttpAdapter(HttpGovernmentAdapter):
    def __init__(self):
        super().__init__("EMERGENCY")


class NidaHttpAdapter(HttpGovernmentAdapter):
    def __init__(self):
        super().__init__("NIDA")


class BrelaHttpAdapter(HttpGovernmentAdapter):
    def __init__(self):
        super().__init__("BRELA")


class TrafficHttpAdapter(HttpGovernmentAdapter):
    def __init__(self):
        super().__init__("TRAFFIC")
