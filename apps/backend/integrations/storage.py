"""Object storage — S3-compatible HTTP put/get (MinIO / AWS / GCS interoperable)."""
from __future__ import annotations

import hashlib
import hmac
import logging
from dataclasses import dataclass
from datetime import datetime, timezone
from urllib.parse import quote

import requests
from django.conf import settings

from .http_client import IntegrationHttpError

logger = logging.getLogger("taifa.integrations.storage")


@dataclass(frozen=True)
class StoredObject:
    bucket: str
    key: str
    etag: str
    size: int
    url: str


class ObjectStorageNotConfigured(RuntimeError):
    pass


class S3CompatibleStorage:
    """Minimal SigV4 PUT/GET against an S3-compatible endpoint.

    TAIFA_OBJECT_STORAGE_JSON:
      {
        "endpoint": "https://s3.amazonaws.com",
        "region": "af-south-1",
        "bucket": "taifa-docs",
        "access_key": "...",
        "secret_key": "...",
        "path_style": true
      }
    """

    def __init__(self):
        cfg = getattr(settings, "TAIFA_OBJECT_STORAGE", None) or {}
        self.endpoint = (cfg.get("endpoint") or "").rstrip("/")
        self.region = cfg.get("region", "us-east-1")
        self.bucket = cfg.get("bucket", "")
        self.access_key = cfg.get("access_key") or ""
        self.secret_key = cfg.get("secret_key") or ""
        self.path_style = bool(cfg.get("path_style", True))
        self.timeout_s = float(cfg.get("timeout_seconds", 30))
        if not (self.endpoint and self.bucket and self.access_key and self.secret_key):
            raise ObjectStorageNotConfigured(
                "object storage not configured (set TAIFA_OBJECT_STORAGE_JSON)"
            )
        self._session = requests.Session()

    def _object_url(self, key: str) -> str:
        encoded = quote(key, safe="/")
        if self.path_style:
            return f"{self.endpoint}/{self.bucket}/{encoded}"
        # virtual-hosted-style
        host = self.endpoint.replace("https://", "").replace("http://", "")
        scheme = "https" if self.endpoint.startswith("https") else "http"
        return f"{scheme}://{self.bucket}.{host}/{encoded}"

    def _sign(self, method: str, url: str, payload: bytes, content_type: str) -> dict:
        # AWS SigV4 lightweight signing for PUT/GET (enough for MinIO + S3).
        now = datetime.now(timezone.utc)
        amz_date = now.strftime("%Y%m%dT%H%M%SZ")
        date_stamp = now.strftime("%Y%m%d")
        payload_hash = hashlib.sha256(payload).hexdigest()
        from urllib.parse import urlparse

        parsed = urlparse(url)
        host = parsed.netloc
        canonical_uri = parsed.path or "/"
        canonical_headers = (
            f"content-type:{content_type}\n"
            f"host:{host}\n"
            f"x-amz-content-sha256:{payload_hash}\n"
            f"x-amz-date:{amz_date}\n"
        )
        signed_headers = "content-type;host;x-amz-content-sha256;x-amz-date"
        canonical_request = "\n".join(
            [method, canonical_uri, "", canonical_headers, signed_headers, payload_hash]
        )
        algorithm = "AWS4-HMAC-SHA256"
        credential_scope = f"{date_stamp}/{self.region}/s3/aws4_request"
        string_to_sign = "\n".join(
            [
                algorithm,
                amz_date,
                credential_scope,
                hashlib.sha256(canonical_request.encode()).hexdigest(),
            ]
        )

        def _sign_key(key: bytes, msg: str) -> bytes:
            return hmac.new(key, msg.encode(), hashlib.sha256).digest()

        k_date = _sign_key(("AWS4" + self.secret_key).encode(), date_stamp)
        k_region = _sign_key(k_date, self.region)
        k_service = _sign_key(k_region, "s3")
        k_signing = _sign_key(k_service, "aws4_request")
        signature = hmac.new(k_signing, string_to_sign.encode(), hashlib.sha256).hexdigest()
        authorization = (
            f"{algorithm} Credential={self.access_key}/{credential_scope}, "
            f"SignedHeaders={signed_headers}, Signature={signature}"
        )
        return {
            "Authorization": authorization,
            "x-amz-date": amz_date,
            "x-amz-content-sha256": payload_hash,
            "Content-Type": content_type,
            "Host": host,
        }

    def put(
        self,
        *,
        key: str,
        payload: bytes,
        content_type: str = "application/octet-stream",
    ) -> StoredObject:
        url = self._object_url(key)
        headers = self._sign("PUT", url, payload, content_type)
        resp = self._session.put(url, data=payload, headers=headers, timeout=self.timeout_s)
        if resp.status_code >= 400:
            raise IntegrationHttpError(
                f"object storage PUT failed: {resp.status_code}",
                status_code=resp.status_code,
                body=resp.text[:500],
            )
        return StoredObject(
            bucket=self.bucket,
            key=key,
            etag=(resp.headers.get("ETag") or "").strip('"'),
            size=len(payload),
            url=url,
        )

    def get(self, *, key: str) -> bytes:
        url = self._object_url(key)
        headers = self._sign("GET", url, b"", "application/octet-stream")
        resp = self._session.get(url, headers=headers, timeout=self.timeout_s)
        if resp.status_code >= 400:
            raise IntegrationHttpError(
                f"object storage GET failed: {resp.status_code}",
                status_code=resp.status_code,
                body=resp.text[:500],
            )
        return resp.content
