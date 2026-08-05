"""Structured JSON logging with secret redaction.

Every log line is a single JSON object suitable for Loki / CloudWatch / Datadog.
Sensitive keys (PIN, password, card, token, secret) are stripped or masked.
"""
from __future__ import annotations

import json
import logging
import re
from datetime import datetime, timezone
from typing import Any

from django.conf import settings

from config.middleware import correlation_fields

_SECRET_KEYS = re.compile(
    r"(password|passwd|secret|token|authorization|api[_-]?key|pin|cvv|card|pan|"
    r"security_credential|passkey|bearer)",
    re.IGNORECASE,
)
_CARD_LIKE = re.compile(r"\b(?:\d[ -]*?){13,19}\b")
_PIN_LIKE = re.compile(r"\bpin[=: ]+\d{4,6}\b", re.IGNORECASE)


def redact_value(key: str, value: Any) -> Any:
    if _SECRET_KEYS.search(key or ""):
        return "[REDACTED]"
    if isinstance(value, str):
        value = _CARD_LIKE.sub("[REDACTED_CARD]", value)
        value = _PIN_LIKE.sub("pin=[REDACTED]", value)
        return value
    if isinstance(value, dict):
        return {k: redact_value(k, v) for k, v in value.items()}
    if isinstance(value, list):
        return [redact_value(key, v) for v in value]
    return value


class JsonLogFormatter(logging.Formatter):
    """Emit one JSON object per log record."""

    def format(self, record: logging.LogRecord) -> str:
        corr = correlation_fields()
        payload: dict[str, Any] = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "severity": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "service": getattr(settings, "SERVICE_NAME", "taifa-payments"),
            "environment": getattr(settings, "ENVIRONMENT_NAME", "unknown"),
            "trace_id": corr.get("trace_id", "-"),
            "span_id": corr.get("span_id", "-"),
            "request_id": getattr(record, "request_id", corr.get("request_id", "-")),
            "correlation_id": corr.get("correlation_id", getattr(record, "request_id", "-")),
            "transaction_id": getattr(record, "transaction_id", corr.get("transaction_id", "")),
            "wallet_id": getattr(record, "wallet_id", corr.get("wallet_id", "")),
            "merchant_id": getattr(record, "merchant_id", ""),
            "user_id": getattr(record, "user_id", corr.get("user_id", "")),
            "owner": getattr(record, "owner", corr.get("owner", "")),
        }
        if record.exc_info:
            payload["exception"] = self.formatException(record.exc_info)
        # Extra fields attached via logger.bind-style extras
        for key, value in record.__dict__.items():
            if key.startswith("_") or key in payload:
                continue
            if key in {
                "name", "msg", "args", "levelname", "levelno", "pathname", "filename",
                "module", "exc_info", "exc_text", "stack_info", "lineno", "funcName",
                "created", "msecs", "relativeCreated", "thread", "threadName",
                "processName", "process", "message", "asctime", "taskName",
            }:
                continue
            payload[key] = redact_value(key, value)
        return json.dumps(payload, default=str, ensure_ascii=False)
