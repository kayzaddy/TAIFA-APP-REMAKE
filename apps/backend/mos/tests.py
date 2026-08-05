"""Taifa Commerce MOS tests — inventory, order pay via enterprise ledger, AI guard."""
from __future__ import annotations

from decimal import Decimal

from django.core.management import call_command
from django.test import TestCase
from rest_framework.test import APITestCase

from enterprise.models import Merchant, MerchantStatus
from payments.journal import post_opening
from payments.models import (
    Transaction,
    TransactionDirection,
    TransactionStatus,
    TransactionType,
)
from payments.money import Currency, Money

from mos import services
from mos.models import Product, ProductKind, StockMovementKind


class MosInventoryAndPayTests(TestCase):
    def setUp(self):
        self.merchant = Merchant.objects.create(
            code="mos-demo-shop",
            legal_name="Demo Shop Ltd",
            status=MerchantStatus.ACTIVE,
            sector="retail",
        )
        self.cm, self.branch, self.wh = services.bootstrap_merchant_ops(merchant=self.merchant)
        self.product = Product.objects.create(
            commerce_merchant=self.cm,
            sku="SOAP-1",
            name="Bar Soap",
            kind=ProductKind.PHYSICAL,
            price_minor=2000,
            cost_minor=1000,
            track_inventory=True,
        )
        self.stock = services.get_or_create_stock(warehouse=self.wh, product=self.product)
        services.adjust_stock(
            stock_item=self.stock,
            kind=StockMovementKind.RECEIVE,
            quantity=Decimal("10"),
            actor="ops",
        )
        payer = "customer-mos-1"
        txn = Transaction.objects.create(
            owner=payer,
            type=TransactionType.TOP_UP,
            status=TransactionStatus.SUCCEEDED,
            direction=TransactionDirection.CREDIT,
            amount_minor=50_000,
            fee_minor=0,
            currency="TZS",
            counterparty="opening",
            method_kind="opening",
            idempotency_key="mos-open-1",
            note="opening",
        )
        post_opening(txn, payer, Money(50_000, Currency.TZS))
        self.payer = payer

    def test_reserve_pay_fulfill(self):
        order = services.create_sales_order(
            commerce_merchant=self.cm,
            lines=[{"product_id": str(self.product.id), "quantity": 2}],
            channel="pos",
            created_by="cashier",
        )
        self.stock.refresh_from_db()
        self.assertEqual(self.stock.reserved, Decimal("2"))
        self.assertEqual(order.total_minor, 4000)

        order = services.pay_sales_order(
            order=order,
            payer_principal=self.payer,
            idempotency_key="mos-pay-1",
        )
        self.assertTrue(order.paid)
        self.assertTrue(order.payment_ref)

        order = services.fulfill_sales_order(order=order, actor="warehouse")
        self.stock.refresh_from_db()
        self.assertEqual(order.status, "fulfilled")
        self.assertEqual(self.stock.on_hand, Decimal("8"))
        self.assertEqual(self.stock.reserved, Decimal("0"))

    def test_insufficient_stock(self):
        with self.assertRaises(services.MosError):
            services.create_sales_order(
                commerce_merchant=self.cm,
                lines=[{"product_id": str(self.product.id), "quantity": 99}],
            )


class MosApiTests(APITestCase):
    def setUp(self):
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "mos-device-1", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="mos-device-1",
        )
        call_command("seed_winga")

    def test_bootstrap_and_assist_blocks_payment(self):
        r = self.client.post(
            "/api/v1/mos/bootstrap",
            {"code": "kiosk-1", "legal_name": "Kiosk One", "business_type": "market_vendor"},
            format="json",
        )
        self.assertEqual(r.status_code, 201)
        mid = r.data["commerce_merchant"]["merchant_id"]
        blocked = self.client.post(
            f"/api/v1/mos/merchants/{mid}/assist",
            {"capability": "authorize_payment"},
            format="json",
        )
        self.assertEqual(blocked.status_code, 400)
        self.assertTrue(blocked.data.get("blocked"))
