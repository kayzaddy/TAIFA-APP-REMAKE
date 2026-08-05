"""Prometheus metrics for Taifa Commerce MOS."""
from __future__ import annotations

try:
    from prometheus_client import Counter
except ImportError:  # pragma: no cover
    class _Noop:
        def labels(self, **kwargs):
            return self

        def inc(self, amount=1):
            return None

    merchants_bootstrapped = _Noop()
    stock_movements = _Noop()
    orders_created = _Noop()
    orders_paid = _Noop()
    orders_fulfilled = _Noop()
    winga_publishes = _Noop()
else:
    merchants_bootstrapped = Counter(
        "taifa_mos_merchants_bootstrapped_total",
        "MOS merchant profiles bootstrapped",
    )
    stock_movements = Counter(
        "taifa_mos_stock_movements_total",
        "Stock movements by kind",
        ["kind"],
    )
    orders_created = Counter(
        "taifa_mos_orders_created_total",
        "Sales orders created by channel",
        ["channel"],
    )
    orders_paid = Counter(
        "taifa_mos_orders_paid_total",
        "Sales orders paid via enterprise capture",
    )
    orders_fulfilled = Counter(
        "taifa_mos_orders_fulfilled_total",
        "Sales orders fulfilled",
    )
    winga_publishes = Counter(
        "taifa_mos_winga_publishes_total",
        "Products published to Winga offerings",
    )
