"""Taifa Platform Python SDK — thin REST client over shared platform services.

Does not implement payments, identity, or ledger logic. Call the authoritative
APIs and reuse device bearer tokens issued by Taifa Identity.
"""
from __future__ import annotations

from typing import Any

import urllib.error
import urllib.request
import json


class TaifaClient:
    def __init__(self, base_url: str, bearer_token: str):
        self.base_url = base_url.rstrip("/")
        self.bearer_token = bearer_token

    def _request(self, method: str, path: str, body: dict | None = None) -> Any:
        url = f"{self.base_url}{path}"
        data = None if body is None else json.dumps(body).encode("utf-8")
        req = urllib.request.Request(
            url,
            data=data,
            method=method,
            headers={
                "Authorization": f"Bearer {self.bearer_token}",
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
        )
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                raw = resp.read().decode("utf-8")
                return json.loads(raw) if raw else {}
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode("utf-8", errors="replace")
            raise RuntimeError(f"HTTP {exc.code}: {detail}") from exc

    def ecosystem_blueprint(self) -> dict:
        return self._request("GET", "/api/v1/ecosystem/blueprint")

    def my_modules(self) -> dict:
        return self._request("GET", "/api/v1/ecosystem/modules")

    def enable_module(self, module_code: str, enabled: bool = True) -> dict:
        return self._request(
            "POST",
            f"/api/v1/ecosystem/modules/{module_code}/enable",
            {"enabled": enabled},
        )

    def invoke_ai(self, capability: str, payload: dict | None = None) -> dict:
        return self._request(
            "POST",
            f"/api/v1/ecosystem/ai/{capability}/invoke",
            {"payload": payload or {}},
        )

    def wallet(self) -> dict:
        return self._request("GET", "/api/v1/payments/wallet")
