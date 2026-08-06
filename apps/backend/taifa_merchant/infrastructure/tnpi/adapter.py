from __future__ import annotations

from typing import Protocol
from uuid import UUID

from taifa_merchant.infrastructure.models import Merchant


class TnpiMerchantPort(Protocol):
    def register_merchant(self, merchant: Merchant) -> str:
        """Returns TNPI merchant external id."""
        ...


class DevTnpiMerchantAdapter:
    """Stub TNPI Merchant API — replace with TIP HTTP client in production."""

    def register_merchant(self, merchant: Merchant) -> str:
        return f"tnpi-dev-{merchant.id.hex[:12]}"
