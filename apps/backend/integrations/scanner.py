"""HTTP malware scanner adapter (ClamAV REST / cloud AV)."""
from __future__ import annotations

import base64

from django.conf import settings

from .http_client import IntegrationHttpClient, IntegrationHttpError


class HttpDocumentScanner:
    """POST document bytes to a configured scanner endpoint.

    Configure MOBILITY_DOCUMENT_SCANNER=integrations.scanner.HttpDocumentScanner
    and TAIFA_DOCUMENT_SCANNER_JSON={"base_url":"...","scan_path":"/scan","api_key":"..."}.
    """

    def __init__(self):
        cfg = getattr(settings, "TAIFA_DOCUMENT_SCANNER", None) or {}
        base_url = (cfg.get("base_url") or "").strip()
        if not base_url:
            raise RuntimeError("TAIFA_DOCUMENT_SCANNER_JSON base_url is required")
        headers = {"Accept": "application/json"}
        api_key = cfg.get("api_key") or ""
        if api_key:
            headers["Authorization"] = f"{cfg.get('auth_scheme', 'Bearer')} {api_key}"
        self._client = IntegrationHttpClient(
            integration="docs.scanner",
            base_url=base_url,
            timeout_s=float(cfg.get("timeout_seconds", 60)),
            default_headers=headers,
        )
        self._path = cfg.get("scan_path", "/v1/scan")

    def scan(self, *, payload: bytes, filename: str, content_type: str) -> bool:
        try:
            resp = self._client.request(
                "POST",
                self._path,
                operation="scan",
                json={
                    "filename": filename,
                    "content_type": content_type,
                    "content_b64": base64.b64encode(payload).decode(),
                },
            )
            data = resp.json() if resp.content else {}
        except IntegrationHttpError:
            return False
        if "clean" in data:
            return bool(data["clean"])
        if "infected" in data:
            return not bool(data["infected"])
        return resp.status_code == 200
