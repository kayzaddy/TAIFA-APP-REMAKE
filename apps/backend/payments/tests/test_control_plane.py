from django.test import TestCase, override_settings

from payments.models import AuditRecord, DomainEvent, DomainEventType, TransactionStatus
from payments.money import Currency, Money
from payments.orchestrator import OrchestratorContext, PaymentOrchestrator
from payments.risk import RiskContext, RiskDenied, RiskEngine
from payments.state_machine import IllegalStateTransition, assert_transition, can_transition
from payments.tests.fakes import build_test_engine


class StateMachineTests(TestCase):
    def test_allows_happy_path(self):
        self.assertTrue(can_transition(TransactionStatus.PENDING, TransactionStatus.APPROVED))
        self.assertTrue(can_transition(TransactionStatus.APPROVED, TransactionStatus.PROCESSING))
        self.assertTrue(can_transition(TransactionStatus.PROCESSING, TransactionStatus.SUCCEEDED))

    def test_rejects_illegal(self):
        with self.assertRaises(IllegalStateTransition):
            assert_transition(TransactionStatus.FAILED, TransactionStatus.SUCCEEDED)
        with self.assertRaises(IllegalStateTransition):
            assert_transition(TransactionStatus.REVERSED, TransactionStatus.PENDING)


class RiskEngineTests(TestCase):
    def setUp(self):
        self.risk = RiskEngine()
        self.amount = Money.major(10_000, Currency.TZS)

    @override_settings(RISK_SANCTIONS_OWNERS=["bad-actor"])
    def test_sanctions_deny(self):
        d = self.risk.evaluate(
            RiskContext(owner="bad-actor", amount=self.amount, operation="transfer")
        )
        self.assertFalse(d.allowed)
        self.assertEqual(d.code, "SANCTIONS_HIT")

    @override_settings(RISK_PER_TXN_LIMIT_MINOR=1000)
    def test_per_txn_limit(self):
        d = self.risk.evaluate(
            RiskContext(owner="amani", amount=Money.major(50, Currency.TZS), operation="transfer")
        )
        self.assertFalse(d.allowed)
        self.assertEqual(d.code, "PER_TXN_LIMIT")

    @override_settings(RISK_VELOCITY_MAX_TXNS=2, RISK_VELOCITY_WINDOW_SECONDS=3600)
    def test_velocity(self):
        engine = build_test_engine()
        engine.open_wallet("amani", Money.major(1_000_000, Currency.TZS))
        engine.initiate_transfer(
            owner="amani", amount=Money.major(1_000, Currency.TZS),
            method_kind="mobile_money", method_ref="+255", operator="airtel_money",
            counterparty="A", idempotency_key="vel-1",
        )
        engine.initiate_transfer(
            owner="amani", amount=Money.major(1_000, Currency.TZS),
            method_kind="mobile_money", method_ref="+255", operator="airtel_money",
            counterparty="B", idempotency_key="vel-2",
        )
        d = self.risk.evaluate(
            RiskContext(owner="amani", amount=Money.major(1_000, Currency.TZS), operation="transfer")
        )
        self.assertEqual(d.code, "VELOCITY_EXCEEDED")


class OrchestratorControlPlaneTests(TestCase):
    def setUp(self):
        self.engine = build_test_engine()
        self.engine.open_wallet("amani", Money.major(1_000_000, Currency.TZS))
        self.orch = PaymentOrchestrator(engine=self.engine)
        self.ctx = OrchestratorContext(actor="amani", device_id="dev-1", ip="127.0.0.1")

    def test_transfer_emits_event_and_audit(self):
        outcome = self.orch.initiate_transfer(
            ctx=self.ctx,
            owner="amani",
            amount=Money.major(5_000, Currency.TZS),
            method_kind="mobile_money",
            method_ref="+255754000891",
            operator="airtel_money",
            counterparty="Juma",
            idempotency_key="orch-1",
        )
        self.assertEqual(outcome.transaction.status, TransactionStatus.SUCCEEDED)
        self.assertTrue(
            DomainEvent.objects.filter(transaction=outcome.transaction).exists()
            or DomainEvent.objects.filter(event_type=DomainEventType.PAYMENT_SETTLED).exists()
        )
        self.assertTrue(AuditRecord.objects.filter(action="payment.transfer", actor="amani").exists())

    @override_settings(RISK_SANCTIONS_OWNERS=["amani"])
    def test_risk_blocks_before_money(self):
        start = self.engine.wallet_balance("amani", Currency.TZS)
        with self.assertRaises(RiskDenied):
            self.orch.initiate_transfer(
                ctx=self.ctx,
                owner="amani",
                amount=Money.major(1_000, Currency.TZS),
                method_kind="mobile_money",
                method_ref="+255",
                operator="airtel_money",
                counterparty="X",
                idempotency_key="orch-deny",
            )
        self.assertEqual(self.engine.wallet_balance("amani", Currency.TZS), start)
        self.assertTrue(
            DomainEvent.objects.filter(event_type=DomainEventType.RISK_DENIED).exists()
        )
