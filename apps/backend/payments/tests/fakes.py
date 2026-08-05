"""Test doubles: an offline M-Pesa gateway (STK push → pending, no network) so
the engine/webhook flow can be exercised deterministically."""
from __future__ import annotations

from payments.engine import TransactionEngine
from payments.gateways.registry import PaymentRouter
from payments.gateways.simulated import (
    AirtelMoneyGateway,
    CardGateway,
    OfflineMpesaGateway,
    SelcomGateway,
)
from payments.orchestrator import PaymentOrchestrator


class FakeMpesaGateway(OfflineMpesaGateway):
    """Test alias — same offline STK behaviour as production-without-credentials."""


def build_test_router() -> PaymentRouter:
    return PaymentRouter([
        FakeMpesaGateway(),
        AirtelMoneyGateway(),
        SelcomGateway(),
        CardGateway(),
    ])


def build_test_engine() -> TransactionEngine:
    return TransactionEngine(router=build_test_router())


def build_test_orchestrator() -> PaymentOrchestrator:
    return PaymentOrchestrator(engine=build_test_engine())
