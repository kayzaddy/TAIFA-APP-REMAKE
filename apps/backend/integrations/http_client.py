"""Reliable HTTP client for production adapters — retries, circuit, timeouts."""
from __future__ import annotations

import logging
import time
from typing import Any

import requests
from django.conf import settings

from .circuit import CircuitOpen, get_breaker
from . import metrics

logger = logging.getLogger("taifa.integrations")


class IntegrationHttpError(Exception):
    def __init__(
        self,
        message: str,
        *,
        status_code: int | None = None,
        retryable: bool = False,
        body: str = "",
    ):
        super().__init__(message)
        self.status_code = status_code
        self.retryable = retryable
        self.body = body


class IntegrationHttpClient:
    """Shared outbound client with TLS, timeouts, retries, and circuit breaker."""

    def __init__(
        self,
        *,
        integration: str,
        base_url: str,
        timeout_s: float | None = None,
        max_retries: int | None = None,
        session: requests.Session | None = None,
        default_headers: dict | None = None,
        verify_tls: bool = True,
    ):
        self.integration = integration
        self.base_url = (base_url or "").rstrip("/")
        self.timeout_s = float(
            timeout_s
            if timeout_s is not None
            else getattr(settings, "TAIFA_INTEGRATION_TIMEOUT_SECONDS", 15)
        )
        self.max_retries = int(
            max_retries
            if max_retries is not None
            else getattr(settings, "TAIFA_INTEGRATION_MAX_RETRIES", 3)
        )
        self._session = session or requests.Session()
        self._default_headers = dict(default_headers or {})
        self.verify_tls = verify_tls
        self._breaker = get_breaker(integration)

    def request(
        self,
        method: str,
        path: str,
        *,
        operation: str = "request",
        headers: dict | None = None,
        json: Any = None,
        data: Any = None,
        params: dict | None = None,
        auth: Any = None,
    ) -> requests.Response:
        if not self.base_url:
            raise IntegrationHttpError(
                f"{self.integration} base_url is not configured",
                retryable=False,
            )
        url = f"{self.base_url}/{path.lstrip('/')}" if path else self.base_url
        hdrs = {**self._default_headers, **(headers or {})}
        last_exc: Exception | None = None

        for attempt in range(self.max_retries + 1):
            started = time.perf_counter()
            try:
                self._breaker.before_call()
                resp = self._session.request(
                    method.upper(),
                    url,
                    headers=hdrs,
                    json=json,
                    data=data,
                    params=params,
                    auth=auth,
                    timeout=self.timeout_s,
                    verify=self.verify_tls,
                )
                latency = time.perf_counter() - started
                if resp.status_code >= 500 or resp.status_code == 429:
                    self._breaker.record_failure()
                    metrics.set_circuit(integration=self.integration, state=self._breaker.status["state"])
                    metrics.observe_request(
                        integration=self.integration,
                        operation=operation,
                        outcome=f"http_{resp.status_code}",
                        latency_s=latency,
                    )
                    if attempt < self.max_retries:
                        metrics.observe_retry(integration=self.integration, operation=operation)
                        time.sleep(min(2**attempt * 0.25, 4.0))
                        continue
                    raise IntegrationHttpError(
                        f"{self.integration} upstream {resp.status_code}",
                        status_code=resp.status_code,
                        retryable=True,
                        body=resp.text[:500],
                    )
                if resp.status_code >= 400:
                    self._breaker.record_success()
                    metrics.observe_request(
                        integration=self.integration,
                        operation=operation,
                        outcome=f"http_{resp.status_code}",
                        latency_s=latency,
                    )
                    raise IntegrationHttpError(
                        f"{self.integration} client error {resp.status_code}",
                        status_code=resp.status_code,
                        retryable=False,
                        body=resp.text[:500],
                    )
                self._breaker.record_success()
                metrics.set_circuit(integration=self.integration, state="closed")
                metrics.observe_request(
                    integration=self.integration,
                    operation=operation,
                    outcome="ok",
                    latency_s=latency,
                )
                return resp
            except CircuitOpen as exc:
                metrics.observe_request(
                    integration=self.integration,
                    operation=operation,
                    outcome="circuit_open",
                    latency_s=time.perf_counter() - started,
                )
                metrics.set_circuit(integration=self.integration, state="open")
                raise IntegrationHttpError(str(exc), retryable=True) from exc
            except requests.Timeout as exc:
                last_exc = exc
                self._breaker.record_failure()
                metrics.observe_request(
                    integration=self.integration,
                    operation=operation,
                    outcome="timeout",
                    latency_s=time.perf_counter() - started,
                )
                if attempt < self.max_retries:
                    metrics.observe_retry(integration=self.integration, operation=operation)
                    time.sleep(min(2**attempt * 0.25, 4.0))
                    continue
            except requests.RequestException as exc:
                last_exc = exc
                self._breaker.record_failure()
                metrics.observe_request(
                    integration=self.integration,
                    operation=operation,
                    outcome="network_error",
                    latency_s=time.perf_counter() - started,
                )
                if attempt < self.max_retries:
                    metrics.observe_retry(integration=self.integration, operation=operation)
                    time.sleep(min(2**attempt * 0.25, 4.0))
                    continue

        raise IntegrationHttpError(
            f"{self.integration} request failed after retries: {last_exc}",
            retryable=True,
        ) from last_exc
