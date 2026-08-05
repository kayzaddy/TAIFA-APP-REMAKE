"""Celery tasks — IVR fallback after SMS timeout."""
from __future__ import annotations

from celery import shared_task
from django.utils import timezone

from trips.models import DispatchOffer, DispatchOfferStatus

from . import metrics
from . import services


@shared_task(name="mobility_channels.ivr_fallback")
def ivr_fallback_task(offer_id: str) -> dict:
    offer = (
        DispatchOffer.objects.select_related("trip", "driver")
        .filter(pk=offer_id)
        .first()
    )
    if offer is None:
        return {"status": "missing"}
    if offer.status != DispatchOfferStatus.PENDING:
        return {"status": "already_responded"}
    if offer.expires_at <= timezone.now():
        return {"status": "expired"}
    metrics.ivr_fallbacks.inc()
    attempt = services.initiate_ivr_offer(offer=offer)
    return {"status": attempt.status, "channel": attempt.channel}


def schedule_ivr_fallback(offer_id) -> None:
    """Schedule IVR 25s after SMS (before 30s offer expiry)."""
    try:
        ivr_fallback_task.apply_async(args=[str(offer_id)], countdown=25)
    except Exception:
        pass
