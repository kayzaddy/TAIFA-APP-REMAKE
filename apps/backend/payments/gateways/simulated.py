"""Sandbox gateways for rails without a wired-up live SDK yet (Airtel, Selcom,
card acquirer). Same contract as the real adapters; swapped out provider by
provider as integrations land."""
from __future__ import annotations

import time

from ..money import Currency, Money
from .base import (
    PaymentAccepted,
    PaymentCapability,
    PaymentFailed,
    PaymentGateway,
    PaymentOperation,
    PaymentPending,
    PaymentProvider,
    PaymentRequest,
    PaymentResult,
)


class SimulatedGateway(PaymentGateway):
    supported_currencies: set[Currency] = set()
    min_amount: Money | None = None
    max_amount: Money | None = None
    charge_is_synchronous: bool = False

    def can_handle(self, request: PaymentRequest) -> bool:
        if request.amount.currency not in self.supported_currencies:
            return False
        needed = {
            PaymentOperation.CHARGE: PaymentCapability.CHARGE,
            PaymentOperation.PAYOUT: PaymentCapability.PAYOUT,
            PaymentOperation.REFUND: PaymentCapability.REFUND,
        }[request.operation]
        if needed not in self.capabilities:
            return False
        amt = request.amount
        if self.min_amount and amt.currency == self.min_amount.currency and amt < self.min_amount:
            return False
        if self.max_amount and amt.currency == self.max_amount.currency and self.max_amount < amt:
            return False
        return True

    def _ref(self) -> str:
        return f"{self.provider.name}-{int(time.time() * 1000):x}"

    def charge(self, request: PaymentRequest) -> PaymentResult:
        if not self.can_handle(request):
            return PaymentFailed(self.provider, code="UNSUPPORTED", message="Cannot handle request.")
        if self.charge_is_synchronous:
            return PaymentAccepted(self.provider, provider_ref=self._ref())
        return PaymentPending(self.provider, provider_ref=self._ref(), raw_status="AWAITING_CUSTOMER")

    def payout(self, request: PaymentRequest) -> PaymentResult:
        if not self.can_handle(request):
            return PaymentFailed(self.provider, code="UNSUPPORTED", message="Cannot handle request.")
        return PaymentAccepted(self.provider, provider_ref=self._ref())

    def refund(self, request: PaymentRequest) -> PaymentResult:
        return PaymentAccepted(self.provider, provider_ref=self._ref(), raw_status="REFUNDED")

    def status(self, provider_ref: str) -> PaymentResult:
        return PaymentAccepted(self.provider, provider_ref=provider_ref)


class AirtelMoneyGateway(SimulatedGateway):
    provider = PaymentProvider.AIRTEL_MONEY
    capabilities = {
        PaymentCapability.CHARGE,
        PaymentCapability.PAYOUT,
        PaymentCapability.STATUS_QUERY,
        PaymentCapability.MOBILE_MONEY,
    }
    supported_currencies = {Currency.TZS}
    min_amount = Money.major(500, Currency.TZS)
    max_amount = Money.major(10_000_000, Currency.TZS)


class SelcomGateway(SimulatedGateway):
    provider = PaymentProvider.SELCOM
    capabilities = {
        PaymentCapability.CHARGE,
        PaymentCapability.PAYOUT,
        PaymentCapability.REFUND,
        PaymentCapability.STATUS_QUERY,
        PaymentCapability.MOBILE_MONEY,
        PaymentCapability.CARD,
        PaymentCapability.BANK,
    }
    supported_currencies = {Currency.TZS, Currency.KES, Currency.USD}
    min_amount = Money.major(100, Currency.TZS)
    max_amount = None


class CardGateway(SimulatedGateway):
    provider = PaymentProvider.CARD_SCHEME
    capabilities = {
        PaymentCapability.CHARGE,
        PaymentCapability.REFUND,
        PaymentCapability.STATUS_QUERY,
        PaymentCapability.CARD,
    }
    supported_currencies = {Currency.TZS, Currency.USD, Currency.EUR, Currency.KES}
    charge_is_synchronous = True
    min_amount = Money.major(1, Currency.USD)
    max_amount = None


class OfflineMpesaGateway(SimulatedGateway):
    """Offline stand-in for Daraja when `MPESA_CONSUMER_KEY` is unset.

    Collection returns [PaymentPending] (same as live STK). Settlement still
    goes through the webhook processor — use the gated demo-complete endpoint
    or a real Daraja callback.
    """

    provider = PaymentProvider.MPESA
    capabilities = {
        PaymentCapability.CHARGE,
        PaymentCapability.PAYOUT,
        PaymentCapability.STATUS_QUERY,
        PaymentCapability.MOBILE_MONEY,
    }
    supported_currencies = {Currency.TZS, Currency.KES}
    min_amount = Money.major(500, Currency.TZS)
    max_amount = Money.major(20_000_000, Currency.TZS)
    charge_is_synchronous = False
