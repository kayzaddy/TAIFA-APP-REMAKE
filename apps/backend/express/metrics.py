"""Prometheus metrics for Taifa Express."""
from __future__ import annotations

try:
    from prometheus_client import Counter
except ImportError:  # pragma: no cover

    class _Noop:
        def labels(self, **kwargs):
            return self

        def inc(self, amount=1):
            return None

    orders_created = _Noop()
    orders_paid = _Noop()
    deliveries_requested = _Noop()
    ai_assists = _Noop()
else:
    orders_created = Counter("taifa_express_orders_created_total", "Express orders created")
    orders_paid = Counter("taifa_express_orders_paid_total", "Express orders paid")
    deliveries_requested = Counter(
        "taifa_express_deliveries_requested_total", "Express delivery trips requested"
    )
    ai_assists = Counter("taifa_express_ai_assists_total", "Express AI shopping assists")
