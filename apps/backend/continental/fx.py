"""FX engine — supplies locked rates to Payments ledger without owning ledgers."""
from __future__ import annotations

from django.utils import timezone

from .models import FxRate


class FxError(Exception):
    pass


def get_rate_e8(*, base: str, quote: str, at=None) -> int:
    """Return quote currency units per 1 base unit, scaled by 1e8."""
    base = base.upper()
    quote = quote.upper()
    if base == quote:
        return 100_000_000
    at = at or timezone.now()
    row = (
        FxRate.objects.filter(
            base_currency=base,
            quote_currency=quote,
            as_of__lte=at,
        )
        .order_by("-as_of")
        .first()
    )
    if row and (row.valid_until is None or row.valid_until >= at):
        return int(row.rate_e8)
    # Try inverse
    inv = (
        FxRate.objects.filter(
            base_currency=quote,
            quote_currency=base,
            as_of__lte=at,
        )
        .order_by("-as_of")
        .first()
    )
    if inv and (inv.valid_until is None or inv.valid_until >= at) and inv.rate_e8:
        # 1/rate * 1e8 = 1e16 / rate_e8
        return int(10_000_000_000_000_000 // int(inv.rate_e8))
    # Via USD bridge
    if base != "USD" and quote != "USD":
        to_usd = get_rate_e8(base=base, quote="USD", at=at)
        usd_to_quote = get_rate_e8(base="USD", quote=quote, at=at)
        return int(to_usd * usd_to_quote // 100_000_000)
    raise FxError(f"no FX rate for {base}/{quote}")


def convert_minor(*, amount_minor: int, from_currency: str, to_currency: str, at=None) -> tuple[int, int]:
    """Convert minor units; returns (converted_minor, rate_e8)."""
    rate = get_rate_e8(base=from_currency, quote=to_currency, at=at)
    converted = amount_minor * rate // 100_000_000
    return converted, rate


def publish_rate(
    *,
    base: str,
    quote: str,
    rate_e8: int,
    source: str = "manual",
    valid_hours: int | None = 24,
) -> FxRate:
    now = timezone.now()
    valid_until = now + timezone.timedelta(hours=valid_hours) if valid_hours else None
    return FxRate.objects.create(
        base_currency=base.upper(),
        quote_currency=quote.upper(),
        rate_e8=rate_e8,
        source=source,
        as_of=now,
        valid_until=valid_until,
    )
