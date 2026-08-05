"""Request correlation for logs, traces, and metrics.

Every inbound request is tagged with a request id (honouring an upstream
`X-Request-ID` from a proxy/load balancer, or minting one). The id is:

- attached to `request.request_id`,
- echoed back in the `X-Request-ID` response header, and
- injected into every log line via [RequestIDLogFilter].

Optional business headers populate wallet/owner/transaction correlation.
"""
from __future__ import annotations

import logging
import re
import time
import uuid
from contextvars import ContextVar

_request_id: ContextVar[str] = ContextVar("request_id", default="-")
_correlation: ContextVar[dict] = ContextVar("correlation", default={})

_HEADER = "X-Request-ID"
_UUID_RE = re.compile(
    r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"
)


def correlation_fields() -> dict:
    base = dict(_correlation.get() or {})
    base.setdefault("request_id", _request_id.get())
    base.setdefault("correlation_id", base.get("request_id", "-"))
    try:
        from config.otel import current_trace_context

        base.update(current_trace_context())
    except Exception:
        base.setdefault("trace_id", "-")
        base.setdefault("span_id", "-")
    return base


def set_business_correlation(**kwargs) -> None:
    """Merge business identifiers into the current request correlation context."""
    current = dict(_correlation.get() or {})
    for key, value in kwargs.items():
        if value is not None and value != "":
            current[key] = str(value)
    _correlation.set(current)


def normalize_path(path: str) -> str:
    """Collapse UUIDs to reduce Prometheus cardinality."""
    return _UUID_RE.sub("{id}", path)


class RequestIDMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        incoming = request.headers.get(_HEADER, "")
        request_id = incoming.strip() or uuid.uuid4().hex
        request.request_id = request_id
        corr = {
            "request_id": request_id,
            "correlation_id": request_id,
            "user_id": request.headers.get("X-User-Id", ""),
            "owner": "",
            "transaction_id": request.headers.get("X-Transaction-Id", ""),
            "wallet_id": request.headers.get("X-Wallet-Id", ""),
        }
        token_rid = _request_id.set(request_id)
        token_corr = _correlation.set(corr)
        try:
            response = self.get_response(request)
        finally:
            _correlation.reset(token_corr)
            _request_id.reset(token_rid)
        response[_HEADER] = request_id
        return response


class RequestIDLogFilter(logging.Filter):
    def filter(self, record: logging.LogRecord) -> bool:
        fields = correlation_fields()
        record.request_id = fields.get("request_id", "-")
        record.trace_id = fields.get("trace_id", "-")
        record.correlation_id = fields.get("correlation_id", "-")
        return True


class HttpMetricsMiddleware:
    """Record HTTP latency and throughput for Prometheus."""

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        if request.path in {"/metrics", "/healthz", "/readyz", "/startupz", "/depsz"}:
            return self.get_response(request)
        started = time.perf_counter()
        response = self.get_response(request)
        elapsed = time.perf_counter() - started
        try:
            from payments.metrics import observe_http_request

            observe_http_request(
                method=request.method,
                path=normalize_path(request.path),
                status=getattr(response, "status_code", 0),
                duration_seconds=elapsed,
            )
        except Exception:  # pragma: no cover — never break requests for metrics
            pass
        return response
