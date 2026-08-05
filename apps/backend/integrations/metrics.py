"""Prometheus metrics for outbound integration adapters."""
from __future__ import annotations

from prometheus_client import Counter, Gauge, Histogram

ADAPTER_REQUESTS = Counter(
    "taifa_integration_requests_total",
    "Outbound integration HTTP attempts",
    ["integration", "operation", "outcome"],
)
ADAPTER_LATENCY = Histogram(
    "taifa_integration_latency_seconds",
    "Outbound integration latency",
    ["integration", "operation"],
    buckets=(0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, 30),
)
ADAPTER_RETRIES = Counter(
    "taifa_integration_retries_total",
    "Outbound integration retries",
    ["integration", "operation"],
)
ADAPTER_CIRCUIT = Gauge(
    "taifa_integration_circuit_state",
    "Circuit state: 0=closed 1=half_open 2=open",
    ["integration"],
)

_CIRCUIT_MAP = {"closed": 0, "half_open": 1, "open": 2}


def observe_request(*, integration: str, operation: str, outcome: str, latency_s: float) -> None:
    ADAPTER_REQUESTS.labels(integration=integration, operation=operation, outcome=outcome).inc()
    ADAPTER_LATENCY.labels(integration=integration, operation=operation).observe(latency_s)


def observe_retry(*, integration: str, operation: str) -> None:
    ADAPTER_RETRIES.labels(integration=integration, operation=operation).inc()


def set_circuit(*, integration: str, state: str) -> None:
    ADAPTER_CIRCUIT.labels(integration=integration).set(_CIRCUIT_MAP.get(state, 0))
