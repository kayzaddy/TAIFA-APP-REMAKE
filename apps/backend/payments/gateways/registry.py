"""PaymentRouter — resolves a request to a concrete rail (mirror of the Dart
`payment_router.dart`). Preference order first, then graceful fallback to the
Selcom aggregator, then any capable rail."""
from __future__ import annotations

from .base import (
    PaymentContractError,
    PaymentGateway,
    PaymentProvider,
    PaymentRequest,
)


class PaymentRouter:
    def __init__(self, gateways: list[PaymentGateway]):
        self._gateways = list(gateways)

    def _preference_for(self, request: PaymentRequest) -> list[PaymentProvider]:
        kind = request.method_kind
        if kind == "mobile_money":
            direct = {
                "mpesa": PaymentProvider.MPESA,
                "airtel_money": PaymentProvider.AIRTEL_MONEY,
                "mixx_by_yas": PaymentProvider.SELCOM,
                "halopesa": PaymentProvider.SELCOM,
            }.get(request.operator, PaymentProvider.SELCOM)
            return [direct, PaymentProvider.SELCOM]
        if kind == "card":
            return [PaymentProvider.CARD_SCHEME, PaymentProvider.SELCOM]
        if kind == "bank":
            return [PaymentProvider.BANK_RAIL, PaymentProvider.SELCOM]
        # Internal wallet transfers never leave the platform.
        return []

    def resolve(self, request: PaymentRequest) -> PaymentGateway:
        for provider in self._preference_for(request):
            for g in self._gateways:
                if g.provider == provider and g.can_handle(request):
                    return g
        for g in self._gateways:
            if g.can_handle(request):
                return g
        raise PaymentContractError(
            f"No payment rail can handle {request.operation.value} of "
            f"{request.amount} via {request.method_kind}."
        )

    def candidates(self, request: PaymentRequest) -> list[PaymentGateway]:
        return [g for g in self._gateways if g.can_handle(request)]
