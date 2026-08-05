"""Prometheus metrics for hybrid dispatch."""
from __future__ import annotations

try:
    from prometheus_client import Counter
except ImportError:  # pragma: no cover

    class _Noop:
        def labels(self, **kwargs):
            return self

        def inc(self, amount=1):
            return None

    offers_sent = _Noop()
    sms_inbound = _Noop()
    ussd_sessions = _Noop()
    ivr_fallbacks = _Noop()
else:
    offers_sent = Counter(
        "taifa_mobility_channel_offers_sent_total",
        "Hybrid dispatch offers sent",
        ["channel"],
    )
    sms_inbound = Counter("taifa_mobility_sms_inbound_total", "Inbound SMS processed")
    ussd_sessions = Counter("taifa_mobility_ussd_sessions_total", "USSD sessions")
    ivr_fallbacks = Counter("taifa_mobility_ivr_fallbacks_total", "IVR fallbacks triggered")
