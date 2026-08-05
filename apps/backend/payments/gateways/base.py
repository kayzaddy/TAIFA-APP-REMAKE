"""PaymentGateway contract — the server mirror of the Flutter interface in
`apps/mobile/lib/features/wallet/payments/payment_gateway.dart`.

Every payment rail (M-Pesa, Airtel, Selcom, a bank, a card acquirer) implements
this one interface. The transaction engine, ledger and API never reference a
concrete provider — the router resolves it. Keeping this identical to the client
is what makes the two aligned by construction.
"""
from __future__ import annotations

import enum
from abc import ABC, abstractmethod
from dataclasses import dataclass, field

from ..money import Money


class PaymentProvider(enum.Enum):
    MPESA = "M-Pesa"
    MIXX_BY_YAS = "Mixx by Yas"
    AIRTEL_MONEY = "Airtel Money"
    HALOPESA = "HaloPesa"
    SELCOM = "Selcom"
    PESAPAL = "Pesapal"
    FLUTTERWAVE = "Flutterwave"
    DPO = "DPO Group"
    AZAMPAY = "AzamPay"
    CARD_SCHEME = "Card"
    BANK_RAIL = "Bank"

    @property
    def display_name(self) -> str:
        return self.value


class PaymentCapability(enum.Enum):
    CHARGE = "charge"
    PAYOUT = "payout"
    REFUND = "refund"
    STATUS_QUERY = "status_query"
    MOBILE_MONEY = "mobile_money"
    CARD = "card"
    BANK = "bank"
    CRYPTO = "crypto"


class PaymentOperation(enum.Enum):
    CHARGE = "charge"
    PAYOUT = "payout"
    REFUND = "refund"


@dataclass(frozen=True)
class PaymentRequest:
    idempotency_key: str
    reference: str  # our transaction id
    amount: Money
    operation: PaymentOperation
    # Method summary the router uses to pick a rail.
    method_kind: str  # mobile_money | card | bank | wallet
    method_ref: str = ""  # msisdn / last4 / account
    operator: str = ""  # mpesa | airtel_money | ...
    narrative: str | None = None
    metadata: dict = field(default_factory=dict)


# === Sealed result hierarchy ===============================================
class PaymentResult:
    provider: PaymentProvider


@dataclass(frozen=True)
class PaymentAccepted(PaymentResult):
    provider: PaymentProvider
    provider_ref: str
    raw_status: str = "ACCEPTED"


@dataclass(frozen=True)
class PaymentPending(PaymentResult):
    """Accepted for processing; the terminal state arrives via webhook/poll
    (e.g. an STK push awaiting the customer's PIN)."""

    provider: PaymentProvider
    provider_ref: str
    raw_status: str = "PENDING"


@dataclass(frozen=True)
class PaymentFailed(PaymentResult):
    provider: PaymentProvider
    code: str
    message: str
    retryable: bool = False
    provider_ref: str | None = None


class PaymentContractError(Exception):
    """Programming/contract error (not an expected decline)."""


class PaymentGateway(ABC):
    provider: PaymentProvider
    capabilities: set[PaymentCapability]

    @abstractmethod
    def can_handle(self, request: PaymentRequest) -> bool: ...

    @abstractmethod
    def charge(self, request: PaymentRequest) -> PaymentResult: ...

    @abstractmethod
    def payout(self, request: PaymentRequest) -> PaymentResult: ...

    @abstractmethod
    def refund(self, request: PaymentRequest) -> PaymentResult: ...

    @abstractmethod
    def status(self, provider_ref: str) -> PaymentResult: ...
