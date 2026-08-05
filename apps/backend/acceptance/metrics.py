"""Prometheus metrics for Merchant Acceptance Platform."""
from __future__ import annotations

try:
    from prometheus_client import Counter
except ImportError:  # pragma: no cover

    class _Noop:
        def labels(self, **kwargs):
            return self

        def inc(self, amount=1):
            return None

    profiles_created = _Noop()
    intents_created = _Noop()
    qr_issued = _Noop()
    links_created = _Noop()
    invoices_created = _Noop()
    checkouts_created = _Noop()
    payments_succeeded = _Noop()
    payments_failed = _Noop()
    receipts_issued = _Noop()
    tap_started = _Noop()
    tap_auth = _Noop()
    tap_succeeded = _Noop()
    tap_failed = _Noop()
else:
    profiles_created = Counter(
        "taifa_map_profiles_created_total",
        "MAP acceptance profiles created",
    )
    intents_created = Counter(
        "taifa_map_intents_created_total",
        "MAP payment intents created",
        ["channel"],
    )
    qr_issued = Counter(
        "taifa_map_qr_issued_total",
        "MAP QR artifacts issued",
        ["kind"],
    )
    links_created = Counter(
        "taifa_map_payment_links_created_total",
        "MAP payment links created",
    )
    invoices_created = Counter(
        "taifa_map_invoices_created_total",
        "MAP digital invoices created",
    )
    checkouts_created = Counter(
        "taifa_map_checkouts_created_total",
        "MAP checkout sessions created",
    )
    payments_succeeded = Counter(
        "taifa_map_payments_succeeded_total",
        "MAP intent payments succeeded via enterprise capture",
        ["channel"],
    )
    payments_failed = Counter(
        "taifa_map_payments_failed_total",
        "MAP intent payments failed",
        ["channel"],
    )
    receipts_issued = Counter(
        "taifa_map_receipts_issued_total",
        "MAP receipts issued",
    )
    tap_started = Counter(
        "taifa_tap_started_total",
        "Tap & Pay sessions started",
        ["channel"],
    )
    tap_auth = Counter(
        "taifa_tap_auth_total",
        "Tap & Pay authentication events",
        ["method"],
    )
    tap_succeeded = Counter(
        "taifa_tap_succeeded_total",
        "Tap & Pay completions",
        ["channel"],
    )
    tap_failed = Counter(
        "taifa_tap_failed_total",
        "Tap & Pay failures",
        ["reason"],
    )
