"""P0 production-gate tests — real-funds readiness blockers."""
from __future__ import annotations

import json
import tempfile
import time
from io import StringIO
from pathlib import Path

from django.contrib.admin.sites import site
from django.core.management import call_command
from django.core.management.base import CommandError
from django.test import SimpleTestCase, TestCase, override_settings
from rest_framework.exceptions import PermissionDenied
from rest_framework.test import APIRequestFactory, APITestCase

from payments.admin import TransactionAdmin
from payments.models import (
    AuditRecord,
    ReconciliationException,
    SettlementMatchStatus,
    Transaction,
    TransactionDirection,
    TransactionStatus,
    TransactionType,
)
from payments.money import Currency, Money
from payments.production_gates import check_production_payment_gates, demo_wallet_funding_allowed
from payments.provider_reconciliation import ingest_settlement_csv, reconcile_batch
from payments.tests.fakes import build_test_engine
from payments.tests.test_webhook_auth import _fake_request
from payments.webhook_auth import assert_mpesa_stk_webhook_trusted, compute_webhook_signature


class P0DemoFundingTests(APITestCase):
    @override_settings(ALLOW_DEMO_WALLET_FUNDING=False)
    def test_register_does_not_mint_demo_money(self):
        resp = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "prod-device-1", "platform": "android"},
            format="json",
        )
        self.assertEqual(resp.status_code, 201)
        self.assertEqual(resp.json()["balance_minor"], 0)

    @override_settings(ALLOW_DEMO_WALLET_FUNDING=True)
    def test_register_can_fund_when_explicitly_allowed(self):
        self.assertTrue(demo_wallet_funding_allowed())
        resp = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "demo-device-1", "platform": "android"},
            format="json",
        )
        self.assertEqual(resp.status_code, 201)
        self.assertEqual(resp.json()["balance_minor"], 284750000)


class P0AdminImmutableTests(TestCase):
    def test_transaction_admin_is_read_only(self):
        admin = TransactionAdmin(Transaction, site)

        class Req:
            pass

        req = Req()
        self.assertFalse(admin.has_add_permission(req))
        self.assertFalse(admin.has_change_permission(req))
        self.assertFalse(admin.has_delete_permission(req))


class P0WebhookSecurityTests(TestCase):
    @override_settings(
        MPESA_WEBHOOK_SHARED_SECRET="s3cret",
        MPESA_WEBHOOK_REQUIRE_HMAC=True,
        MPESA_WEBHOOK_FAIL_CLOSED=True,
        MPESA_WEBHOOK_ALLOWED_IPS=[],
        MPESA_WEBHOOK_MAX_SKEW_SECONDS=300,
    )
    def test_hmac_required_and_replay_blocked(self):
        body = {
            "Body": {
                "stkCallback": {
                    "CheckoutRequestID": "ws_HMAC_1",
                    "ResultCode": 0,
                    "ResultDesc": "ok",
                }
            }
        }
        raw = json.dumps(body, separators=(",", ":")).encode()
        ts = str(int(time.time()))
        sig = compute_webhook_signature("s3cret", ts, raw)
        factory = APIRequestFactory()
        req = factory.post(
            "/api/v1/payments/webhooks/mpesa/stk",
            raw,
            content_type="application/json",
            HTTP_X_TAIFA_WEBHOOK_TIMESTAMP=ts,
            HTTP_X_TAIFA_WEBHOOK_SIGNATURE=sig,
        )
        req.data = body
        assert_mpesa_stk_webhook_trusted(req)
        with self.assertRaises(PermissionDenied):
            assert_mpesa_stk_webhook_trusted(req)

    @override_settings(
        MPESA_WEBHOOK_SHARED_SECRET="",
        MPESA_WEBHOOK_FAIL_CLOSED=True,
        MPESA_WEBHOOK_REQUIRE_HMAC=False,
    )
    def test_fail_closed_without_secret(self):
        with self.assertRaises(PermissionDenied):
            assert_mpesa_stk_webhook_trusted(
                _fake_request(
                    data={
                        "Body": {
                            "stkCallback": {
                                "CheckoutRequestID": "ws_X",
                                "ResultCode": 0,
                            }
                        }
                    }
                )
            )


class P0OrchestratorSettleAuditTests(TestCase):
    def test_webhook_settle_writes_audit(self):
        from payments.orchestrator import OrchestratorContext, PaymentOrchestrator

        engine = build_test_engine()
        engine.open_wallet("amani", Money.major(100_000, Currency.TZS))
        outcome = engine.initiate_topup(
            owner="amani",
            amount=Money.major(10_000, Currency.TZS),
            msisdn="+255754000891",
            idempotency_key="p0-orch-topup",
        )
        checkout = outcome.transaction.provider_ref
        orch = PaymentOrchestrator(engine=engine)
        before = AuditRecord.objects.count()
        orch.settle_mpesa_stk_callback(
            {
                "Body": {
                    "stkCallback": {
                        "CheckoutRequestID": checkout,
                        "ResultCode": 0,
                        "ResultDesc": "ok",
                    }
                }
            },
            ctx=OrchestratorContext(actor="mpesa-webhook"),
        )
        self.assertGreater(AuditRecord.objects.count(), before)
        outcome.transaction.refresh_from_db()
        self.assertEqual(outcome.transaction.status, TransactionStatus.SUCCEEDED)


class P0ProductionChecksTests(SimpleTestCase):
    @override_settings(
        DEBUG=False,
        RUNNING_TESTS=False,
        ALLOW_DEMO_WALLET_FUNDING=True,
        ALLOW_DEMO_STK=False,
        WITHDRAWAL_AUTO_APPROVE=False,
        MPESA_WEBHOOK_SHARED_SECRET="x",
        RISK_PER_TXN_LIMIT_MINOR=1,
        RISK_DAILY_DEBIT_LIMIT_MINOR=1,
        RISK_ALLOW_UNLIMITED=False,
    )
    def test_demo_funding_flag_fails_check(self):
        errs = check_production_payment_gates(None)
        ids = {e.id for e in errs}
        self.assertIn("payments.E001", ids)


class P0ProviderReconTests(TestCase):
    def test_match_and_exceptions(self):
        engine = build_test_engine()
        engine.open_wallet("amani", Money.major(1_000_000, Currency.TZS))
        send = engine.initiate_transfer(
            owner="amani",
            amount=Money.major(10_000, Currency.TZS),
            method_kind="mobile_money",
            method_ref="+255",
            operator="airtel_money",
            counterparty="Juma",
            idempotency_key="p0-recon-send",
        ).transaction
        self.assertTrue(send.provider_ref)
        txn2 = Transaction.objects.create(
            owner="amani",
            type=TransactionType.SEND_MONEY,
            status=TransactionStatus.SUCCEEDED,
            direction=TransactionDirection.DEBIT,
            amount_minor=5000,
            currency="TZS",
            counterparty="x",
            method_kind="mobile_money",
            provider="M-Pesa",
            provider_ref="ref-mismatch",
            idempotency_key="p0-recon-mm",
        )
        csv = (
            "provider_ref,amount_minor,currency,direction\n"
            f"{send.provider_ref},{send.amount_minor},TZS,debit\n"
            "unknown-ref,100,TZS,debit\n"
            f"{txn2.provider_ref},9999,TZS,debit\n"
        )
        batch = ingest_settlement_csv(provider="mpesa", filename="day.csv", content=csv)
        report = reconcile_batch(batch)
        self.assertGreaterEqual(report.matched, 1)
        self.assertGreater(report.exceptions, 0)
        self.assertTrue(ReconciliationException.objects.filter(batch=batch).exists())
        statuses = set(batch.lines.values_list("match_status", flat=True))
        self.assertTrue(
            SettlementMatchStatus.AMOUNT_MISMATCH in statuses
            or SettlementMatchStatus.UNEXPECTED in statuses
        )

    def test_management_command_exits_on_exceptions(self):
        csv = "provider_ref,amount_minor,currency,direction\nbogus,1,TZS,debit\n"
        with tempfile.NamedTemporaryFile("w", suffix=".csv", delete=False) as f:
            f.write(csv)
            path = f.name
        out = StringIO()
        with self.assertRaises(CommandError):
            call_command("ingest_settlement_csv", path, "--reconcile", stdout=out)
        Path(path).unlink(missing_ok=True)
