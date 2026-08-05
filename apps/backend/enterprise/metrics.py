"""Enterprise platform Prometheus metrics."""
from __future__ import annotations

from prometheus_client import Counter, Gauge

from payments.metrics import _registry

from .models import (
    ChargebackCase,
    ChargebackStatus,
    Merchant,
    MerchantSettlement,
    MerchantSettlementStatus,
    MerchantStatus,
)

MERCHANTS_ACTIVE = Gauge(
    "taifa_merchants_active",
    "Active merchants",
    registry=_registry,
)
SETTLEMENTS_BY_STATUS = Gauge(
    "taifa_merchant_settlements",
    "Merchant settlements by status",
    ["status"],
    registry=_registry,
)
CHARGEBACKS_OPEN = Gauge(
    "taifa_chargebacks_open",
    "Open chargeback cases",
    registry=_registry,
)
PLATFORM_CAPTURES = Counter(
    "taifa_merchant_captures_total",
    "Merchant payment captures",
    registry=_registry,
)
OUTBOX_PENDING = Gauge(
    "taifa_event_outbox_pending",
    "Unpublished event outbox rows",
    registry=_registry,
)


def refresh_enterprise_metrics() -> None:
    MERCHANTS_ACTIVE.set(Merchant.objects.filter(status=MerchantStatus.ACTIVE).count())
    for status, _ in MerchantSettlementStatus.choices:
        SETTLEMENTS_BY_STATUS.labels(status=status).set(
            MerchantSettlement.objects.filter(status=status).count()
        )
    CHARGEBACKS_OPEN.set(
        ChargebackCase.objects.exclude(
            status__in=[ChargebackStatus.WON, ChargebackStatus.LOST, ChargebackStatus.REVERSED]
        ).count()
    )
    from .models import EventOutbox

    OUTBOX_PENDING.set(EventOutbox.objects.filter(published=False).count())
