"""Phase 3 enterprise financial platform tests."""
from __future__ import annotations

from django.test import TestCase
from django.utils import timezone

from enterprise import approval, event_bus, financial_reports, rules, workflow
from enterprise.models import (
    BusinessRule,
    Merchant,
    MerchantSettlementStatus,
    MerchantStatus,
    TreasuryBankAccount,
    TreasuryTransfer,
    WorkflowDefinition,
)
from enterprise.orchestrator import PlatformContext, default_platform
from enterprise.regulatory import generate_auditor_pack, generate_bot_daily
from payments import journal, ledger
from payments.engine import default_engine
from payments.models import (
    LedgerEntryKind,
    Transaction,
    TransactionDirection,
    TransactionStatus,
    TransactionType,
)
from payments.money import Currency, Money
from payments.reconciliation import run_reconciliation


class MerchantSettlementFlowTests(TestCase):
    def setUp(self):
        self.engine = default_engine()
        self.platform = default_platform()
        self.ctx = PlatformContext(actor="ops-maker")
        self.engine.open_wallet("payer-1", Money.major(1_000_000, Currency.TZS))
        self.merchant = Merchant.objects.create(
            code="duka-1",
            legal_name="Duka Limited",
            status=MerchantStatus.ACTIVE,
            fee_bps=100,
            tax_bps=0,
            commission_bps=0,
            bank_code="crdb",
        )

    def test_capture_settlement_chargeback_accounting(self):
        amount = Money.major(100_000, Currency.TZS)
        txn = self.platform.capture_merchant_payment(
            ctx=self.ctx,
            merchant=self.merchant,
            payer_owner="payer-1",
            amount=amount,
            idempotency_key="cap-1",
        )
        self.assertEqual(txn.status, "succeeded")
        self.assertIsNotNone(txn.ledger_entry_id)

        settlement = self.platform.create_settlement(
            ctx=self.ctx,
            merchant=self.merchant,
            amount=amount,
            period_start=timezone.now(),
            period_end=timezone.now(),
            idempotency_key="set-1",
            require_approval_above_minor=10**15,
        )
        self.assertEqual(settlement.status, MerchantSettlementStatus.APPROVED)
        settlement = self.platform.execute_settlement(ctx=self.ctx, settlement=settlement)
        self.assertEqual(settlement.status, MerchantSettlementStatus.COMPLETED)
        self.assertTrue(settlement.statement_ref)

        self.engine.open_wallet("payer-2", Money.major(500_000, Currency.TZS))
        cap2 = self.platform.capture_merchant_payment(
            ctx=self.ctx,
            merchant=self.merchant,
            payer_owner="payer-2",
            amount=Money.major(50_000, Currency.TZS),
            idempotency_key="cap-2",
        )
        case = self.platform.open_chargeback(
            ctx=self.ctx,
            merchant=self.merchant,
            original=cap2,
            amount=Money.major(10_000, Currency.TZS),
            idempotency_key="cb-1",
            reason_code="4855",
        )
        case = self.platform.transition_chargeback(
            ctx=self.ctx, case=case, to_status="evidence_requested"
        )
        case = self.platform.transition_chargeback(
            ctx=self.ctx, case=case, to_status="evidence_submitted", evidence={"receipt": "yes"}
        )
        case = self.platform.transition_chargeback(ctx=self.ctx, case=case, to_status="won")
        self.assertEqual(case.status, "won")
        self.assertIsNotNone(case.resolve_transaction_id)

        recon = run_reconciliation(record=True)
        self.assertTrue(recon.ok)

        self.assertGreater(event_bus.drain_outbox(limit=50), 0)

    def test_rules_override_fee(self):
        BusinessRule.objects.create(
            code="healthcare-fee",
            category="fee",
            priority=10,
            conditions={"sector": "healthcare"},
            actions={"fee_bps": 50},
        )
        comps = rules.fee_components(
            amount_minor=1_000_000,
            merchant_fee_bps=150,
            merchant_tax_bps=0,
            merchant_commission_bps=0,
            sector="healthcare",
        )
        self.assertEqual(comps["fee_minor"], 1_000_000 * 50 // 10_000)
        self.assertIn("healthcare-fee", comps["rules"])


class TreasuryAndReportsTests(TestCase):
    def test_treasury_transfer_and_reports(self):
        a = TreasuryBankAccount.objects.create(
            code="nmb-op",
            bank_name="NMB",
            account_number_masked="****1",
            kind="operating",
            currency="TZS",
            ledger_bank_code="nmb",
        )
        b = TreasuryBankAccount.objects.create(
            code="crdb-set",
            bank_name="CRDB",
            account_number_masked="****2",
            kind="settlement",
            currency="TZS",
            ledger_bank_code="crdb",
        )
        seed = Transaction.objects.create(
            owner="treasury",
            type=TransactionType.TREASURY_TRANSFER,
            status=TransactionStatus.SUCCEEDED,
            direction=TransactionDirection.DEBIT,
            amount_minor=500_000,
            currency="TZS",
            counterparty="seed",
            method_kind="bank",
            idempotency_key="seed-nmb",
        )
        ledger.post_entry(
            seed,
            "seed banks",
            [
                ledger.PostingSpec.debit(
                    journal.external_bank("crdb", Currency.TZS), Money(500_000, Currency.TZS)
                ),
                ledger.PostingSpec.credit(
                    journal.external_bank("nmb", Currency.TZS), Money(500_000, Currency.TZS)
                ),
            ],
            kind=LedgerEntryKind.TREASURY,
        )
        transfer = TreasuryTransfer.objects.create(
            from_account=a,
            to_account=b,
            amount_minor=100_000,
            currency="TZS",
            idempotency_key="tt-1",
        )
        result = default_platform()._execute_treasury_transfer(
            ctx=PlatformContext(actor="treasurer"), transfer=transfer
        )
        self.assertEqual(result.status, "completed")
        self.assertTrue(financial_reports.trial_balance(currency="TZS"))
        self.assertIn("assets_minor", financial_reports.balance_sheet(currency="TZS"))
        self.assertEqual(generate_bot_daily().report_type, "bot_daily")
        self.assertIn("trial_balance", generate_auditor_pack().payload)


class WorkflowApprovalTests(TestCase):
    def test_workflow_and_approval(self):
        WorkflowDefinition.objects.create(
            code="merchant_onboarding",
            name="Merchant Onboarding",
            steps=[{"code": "kyc"}, {"code": "risk"}, {"code": "activate"}],
        )
        inst = workflow.start(
            definition_code="merchant_onboarding",
            resource_type="merchant",
            resource_id="x",
        )
        workflow.advance(instance_id=inst.id, actor="ops", note="kyc ok")
        workflow.advance(instance_id=inst.id, actor="risk", note="ok")
        inst = workflow.advance(instance_id=inst.id, actor="lead", note="activate")
        self.assertEqual(inst.status, "completed")

        req = approval.request_approval(
            action="settlement.execute",
            resource_type="merchant_settlement",
            resource_id="abc",
            maker="maker1",
            amount_minor=100,
            threshold_minor=0,
        )
        decided = approval.decide(request_id=req.id, checker="checker1", approve=True)
        self.assertEqual(decided.status, "approved")
