"""Winga brokerage platform tests — commission, settlement, workflow."""
from __future__ import annotations

from django.core.management import call_command
from django.test import TestCase
from rest_framework.test import APITestCase

from payments.journal import post_opening
from payments.models import Transaction, TransactionDirection, TransactionStatus, TransactionType
from payments.money import Currency, Money

from winga import commission as commission_engine
from winga.models import (
    BrokerageDeal,
    BrokerageDomain,
    CommissionEventStatus,
    CommissionKind,
    CommissionRule,
    DealStage,
    ProviderProfile,
    VerificationStatus,
    WingaProfile,
)
from winga.services import advance_deal, open_deal
from winga.settlement import collect_deal_payment, settle_commissions


class WingaCommissionEngineTests(TestCase):
    def setUp(self):
        self.domain = BrokerageDomain.objects.create(
            code="retail", name="Retail", default_commission_bps=500
        )
        self.winga = WingaProfile.objects.create(
            principal="winga-1",
            display_name="Asha Winga",
            verification_status=VerificationStatus.VERIFIED,
        )
        self.provider = ProviderProfile.objects.create(
            principal="provider-1",
            legal_name="Duka Ltd",
            verification_status=VerificationStatus.VERIFIED,
        )
        self.deal = BrokerageDeal.objects.create(
            reference="WG-TEST1",
            domain=self.domain,
            winga=self.winga,
            provider=self.provider,
            customer_principal="customer-1",
            amount_minor=100_000,
            currency="TZS",
            stage=DealStage.ACCEPTED,
        )

    def test_percentage_default_domain(self):
        calcs = commission_engine.calculate(deal=self.deal)
        self.assertEqual(len(calcs), 1)
        self.assertEqual(calcs[0].commission_minor, 5_000)
        self.assertEqual(calcs[0].bps_applied, 500)

    def test_flat_rule(self):
        rule = CommissionRule.objects.create(
            code="flat-retail",
            name="Flat",
            kind=CommissionKind.FLAT,
            domain=self.domain,
            flat_minor=2_500,
            priority=10,
        )
        calcs = commission_engine.calculate(deal=self.deal, rule=rule)
        self.assertEqual(calcs[0].commission_minor, 2_500)

    def test_tiered_rule(self):
        rule = CommissionRule.objects.create(
            code="tier-retail",
            name="Tiered",
            kind=CommissionKind.TIERED,
            domain=self.domain,
            tiers=[
                {"min_minor": 0, "max_minor": 50_000, "bps": 1000},
                {"min_minor": 50_001, "max_minor": None, "bps": 400},
            ],
            priority=10,
        )
        calcs = commission_engine.calculate(deal=self.deal, rule=rule)
        self.assertEqual(calcs[0].bps_applied, 400)
        self.assertEqual(calcs[0].commission_minor, 4_000)

    def test_multi_level(self):
        rule = CommissionRule.objects.create(
            code="ml-retail",
            name="ML",
            kind=CommissionKind.MULTI_LEVEL,
            domain=self.domain,
            multi_level=[{"level": 1, "bps": 500}, {"level": 2, "bps": 100}],
            priority=10,
        )
        calcs = commission_engine.calculate(deal=self.deal, rule=rule)
        self.assertEqual(len(calcs), 2)
        self.assertEqual(calcs[0].commission_minor, 5_000)
        self.assertEqual(calcs[1].commission_minor, 1_000)


class WingaSettlementTests(TestCase):
    def setUp(self):
        self.domain = BrokerageDomain.objects.create(
            code="professional", name="Professional", default_commission_bps=1000
        )
        self.winga = WingaProfile.objects.create(
            principal="winga-settle",
            display_name="Broker",
            verification_status=VerificationStatus.VERIFIED,
        )
        self.provider = ProviderProfile.objects.create(
            principal="provider-settle",
            legal_name="Pro Co",
            verification_status=VerificationStatus.VERIFIED,
        )
        self.customer = "customer-settle"
        txn = Transaction.objects.create(
            owner=self.customer,
            type=TransactionType.TOP_UP,
            status=TransactionStatus.SUCCEEDED,
            direction=TransactionDirection.CREDIT,
            amount_minor=500_000,
            fee_minor=0,
            currency="TZS",
            counterparty="opening",
            method_kind="opening",
            idempotency_key="winga-open-1",
            note="opening",
        )
        post_opening(txn, self.customer, Money(500_000, Currency.TZS))

        self.deal = open_deal(
            winga=self.winga,
            provider=self.provider,
            customer_principal=self.customer,
            domain=self.domain,
            amount_minor=100_000,
            currency="TZS",
            actor=self.customer,
        )
        advance_deal(deal=self.deal, to_stage=DealStage.ACCEPTED, actor=self.customer)

    def test_pay_and_settle_commission(self):
        deal = collect_deal_payment(
            deal=self.deal, actor=self.customer, idempotency_key="winga-pay-1"
        )
        self.assertTrue(deal.payment_ref)
        self.assertEqual(deal.stage, DealStage.PAYMENT)

        events = settle_commissions(deal=deal, actor="ops")
        self.assertTrue(events)
        self.assertEqual(events[0].status, CommissionEventStatus.SETTLED)
        self.assertTrue(events[0].ledger_txn_id)
        deal.refresh_from_db()
        self.assertEqual(deal.stage, DealStage.COMMISSION_PAYOUT)
        self.assertEqual(events[0].commission_minor, 10_000)


class WingaApiTests(APITestCase):
    def setUp(self):
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "winga-device-1", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="winga-device-1",
        )
        call_command("seed_winga")

    def test_domains_and_catalog(self):
        r = self.client.get("/api/v1/winga/domains")
        self.assertEqual(r.status_code, 200)
        self.assertGreaterEqual(len(r.data), 10)

    def test_assist_blocks_payment_authorization(self):
        r = self.client.post(
            "/api/v1/winga/assist",
            {"capability": "authorize_payment", "payload": {}},
            format="json",
        )
        self.assertEqual(r.status_code, 400)
