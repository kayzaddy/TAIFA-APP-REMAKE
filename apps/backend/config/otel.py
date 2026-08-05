"""Optional OpenTelemetry distributed tracing.

Activated when OTEL_EXPORTER_OTLP_ENDPOINT (or OTEL_SDK_DISABLED=false with
endpoint) is configured. Soft-imports so the service boots without OTel packages
in local/test environments that omit them.
"""
from __future__ import annotations

import logging
import os

logger = logging.getLogger(__name__)


def setup_tracing() -> bool:
    """Instrument Django / requests / Celery when OTel is configured.

    Returns True if tracing was enabled.
    """
    if os.environ.get("OTEL_SDK_DISABLED", "").lower() in {"1", "true", "yes"}:
        return False
    endpoint = os.environ.get("OTEL_EXPORTER_OTLP_ENDPOINT", "").strip()
    if not endpoint:
        return False

    try:
        from opentelemetry import trace
        from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
        from opentelemetry.sdk.resources import Resource
        from opentelemetry.sdk.trace import TracerProvider
        from opentelemetry.sdk.trace.export import BatchSpanProcessor
    except ImportError:
        logger.warning("OTEL endpoint set but opentelemetry packages are not installed")
        return False

    service = os.environ.get("OTEL_SERVICE_NAME", "taifa-payments")
    env = os.environ.get("TAIFA_ENVIRONMENT", os.environ.get("ENVIRONMENT", "production"))
    resource = Resource.create(
        {
            "service.name": service,
            "deployment.environment": env,
        }
    )
    provider = TracerProvider(resource=resource)
    traces_url = endpoint if endpoint.rstrip("/").endswith("/v1/traces") else (
        endpoint.rstrip("/") + "/v1/traces"
    )
    exporter = OTLPSpanExporter(endpoint=traces_url)
    provider.add_span_processor(BatchSpanProcessor(exporter))
    trace.set_tracer_provider(provider)

    try:
        from opentelemetry.instrumentation.django import DjangoInstrumentor

        DjangoInstrumentor().instrument()
    except Exception as exc:  # pragma: no cover
        logger.warning("Django OTel instrumentation failed: %s", exc)

    try:
        from opentelemetry.instrumentation.requests import RequestsInstrumentor

        RequestsInstrumentor().instrument()
    except Exception as exc:  # pragma: no cover
        logger.warning("requests OTel instrumentation failed: %s", exc)

    try:
        from opentelemetry.instrumentation.celery import CeleryInstrumentor

        CeleryInstrumentor().instrument()
    except Exception as exc:  # pragma: no cover
        logger.warning("Celery OTel instrumentation failed: %s", exc)

    logger.info("OpenTelemetry tracing enabled → %s", endpoint)
    return True


def current_trace_context() -> dict[str, str]:
    """Return trace_id / span_id for log correlation (empty when OTel off)."""
    try:
        from opentelemetry import trace

        span = trace.get_current_span()
        ctx = span.get_span_context()
        if not ctx or not ctx.is_valid:
            return {"trace_id": "-", "span_id": "-"}
        return {
            "trace_id": format(ctx.trace_id, "032x"),
            "span_id": format(ctx.span_id, "016x"),
        }
    except Exception:
        return {"trace_id": "-", "span_id": "-"}
