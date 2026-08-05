"""Taifa Express tests — fulfillment orchestration, packages, settlement plan."""
from __future__ import annotations

from django.core.management import call_command
from django.test import TestCase
from rest_framework.test import APITestCase

from commerce.models import FoodOrder
from express import services
from express.list_parser import parse_line, parse_shopping_list
from express.models import ExpressOrder, ExpressOrderStatus, ExpressProduct, SettlementStatus
from payments.journal import post_opening
from payments.models import (
    Transaction,
    TransactionDirection,
    TransactionStatus,
    TransactionType,
)
from payments.money import Currency, Money
from trips.models import Delivery


class ExpressServiceTests(TestCase):
    def setUp(self):
        call_command("seed_express")
        self.owner = "xp-customer-1"
        txn = Transaction.objects.create(
            owner=self.owner,
            type=TransactionType.TOP_UP,
            status=TransactionStatus.SUCCEEDED,
            direction=TransactionDirection.CREDIT,
            amount_minor=200_000,
            fee_minor=0,
            currency="TZS",
            counterparty="opening",
            method_kind="opening",
            idempotency_key="xp-open-1",
            note="opening",
        )
        post_opening(txn, self.owner, Money(200_000, Currency.TZS))

    def test_rank_nearby_stores(self):
        ranked = services.rank_stores(
            customer_lat=-6.75,
            customer_lng=39.28,
            product_names=["Milk", "Bread"],
        )
        self.assertTrue(ranked)
        self.assertEqual(ranked[0]["code"], "xp-karibu-mart")

    def test_ai_basket_breakfast(self):
        basket = services.ai_build_basket(prompt="Need breakfast")
        self.assertEqual(basket["theme"], "breakfast")
        self.assertTrue(basket["items"])
        self.assertIn("never authorizes", basket["disclaimer"].lower())

    def test_parse_line_quantities(self):
        self.assertEqual(parse_line("2 Milk")["qty"], 2)
        self.assertEqual(parse_line("Milk x2")["qty"], 2)
        self.assertEqual(parse_line("Two Milk")["qty"], 2)
        self.assertEqual(parse_line("Milk 2L")["unit"], "l")
        self.assertEqual(parse_line("Cooking Oil")["name_key"], "cooking oil")

    def test_smart_shopping_list_match(self):
        result = parse_shopping_list(
            text="Milk\nBread\nEggs\n2 Soap\nCook Oil\nUnknown Widget",
            customer_lat=-6.75,
            customer_lng=39.28,
        )
        names = {m["name"].lower() for m in result["matched"]}
        self.assertTrue(any("milk" in n for n in names))
        self.assertTrue(any("bread" in n for n in names))
        self.assertTrue(any("oil" in n for n in names))
        soap = next(m for m in result["matched"] if "soap" in m["name"].lower())
        self.assertEqual(soap["qty"], 2)
        self.assertTrue(result["unknown"])
        self.assertTrue(result["items"])

    def test_checkout_package_settlement_and_ready_dispatch(self):
        order = services.checkout(
            owner=self.owner,
            items=[{"name": "Milk", "qty": 1}, {"name": "Bread", "qty": 1}],
            customer_lat=-6.75,
            customer_lng=39.28,
            customer_address="Masaki",
            idempotency_key="xp-checkout-1",
            auto_ready=True,
        )
        self.assertTrue(order.payment_ref)
        self.assertTrue(order.package_code)
        self.assertTrue(order.package_qr.startswith("taifa://express/pkg/"))
        self.assertEqual(order.settlement_status, SettlementStatus.ALLOCATED)
        self.assertEqual(order.settlement_plan["allocations"][0]["party"], "merchant")
        self.assertTrue(order.food_order_id)
        food = FoodOrder.objects.get(id=order.food_order_id)
        self.assertEqual(food.payment_ref, order.payment_ref)
        milk = ExpressProduct.objects.get(store=order.store, sku="MILK-1L")
        self.assertLess(milk.stock_qty, 40)
        events = [e["event"] for e in order.timeline]
        self.assertIn("merchant_found", events)
        self.assertIn("ready", events)
        self.assertIn("settlement_allocated", events)
        # rider_assigned if drivers exist, else stays ready with delivery_pending
        self.assertIn(
            order.status,
            {
                ExpressOrderStatus.RIDER_ASSIGNED,
                ExpressOrderStatus.READY,
            },
        )

    def test_merchant_ready_creates_pod(self):
        order = services.checkout(
            owner=self.owner,
            items=[{"name": "Eggs", "qty": 1}],
            customer_lat=-6.75,
            customer_lng=39.28,
            customer_address="Oysterbay",
            idempotency_key="xp-checkout-pod",
            auto_ready=False,
        )
        self.assertEqual(order.status, ExpressOrderStatus.PREPARING)
        order = services.merchant_ready(order=order, actor="merchant-1")
        if order.trip_id:
            self.assertTrue(order.delivery_id)
            self.assertTrue(Delivery.objects.filter(id=order.delivery_id).exists())
            self.assertTrue(order.delivery_pin)


class ExpressApiTests(APITestCase):
    def setUp(self):
        call_command("seed_express")
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "xp-device-1", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="xp-device-1",
        )
        payer = "xp-device-1"
        txn = Transaction.objects.create(
            owner=payer,
            type=TransactionType.TOP_UP,
            status=TransactionStatus.SUCCEEDED,
            direction=TransactionDirection.CREDIT,
            amount_minor=200_000,
            fee_minor=0,
            currency="TZS",
            counterparty="opening",
            method_kind="opening",
            idempotency_key="xp-api-open-1",
            note="opening",
        )
        post_opening(txn, payer, Money(200_000, Currency.TZS))

    def test_products_search(self):
        res = self.client.get("/api/v1/express/products", {"q": "Milk"})
        self.assertEqual(res.status_code, 200)
        self.assertTrue(res.data)
        self.assertTrue(any("Milk" in p["name"] for p in res.data))

    def test_quote_api(self):
        res = self.client.post(
            "/api/v1/express/quote",
            {
                "items": [{"name": "Milk", "qty": 1}],
                "lat": -6.75,
                "lng": 39.28,
            },
            format="json",
        )
        self.assertEqual(res.status_code, 200, res.data)
        self.assertGreater(res.data["total_minor"], 0)
        self.assertIn("platform_fee_minor", res.data)

    def test_list_parse_api(self):
        res = self.client.post(
            "/api/v1/express/list/parse",
            {
                "text": "Milk\nBread\nEggs\nRice\nSugar\nSoap\nCooking Oil\nTomatoes",
                "lat": -6.75,
                "lng": 39.28,
            },
            format="json",
        )
        self.assertEqual(res.status_code, 200, res.data)
        self.assertGreaterEqual(len(res.data["matched"]), 5)
        self.assertTrue(res.data["items"])

    def test_checkout_api(self):
        res = self.client.post(
            "/api/v1/express/checkout",
            {
                "items": [{"name": "Milk", "qty": 1}, {"name": "Eggs", "qty": 1}],
                "lat": -6.75,
                "lng": 39.28,
                "address": "Oysterbay",
                "notes": "Gate 2",
                "auto_ready": True,
            },
            format="json",
            HTTP_IDEMPOTENCY_KEY="xp-api-checkout-1",
        )
        self.assertEqual(res.status_code, 201, res.data)
        self.assertTrue(res.data["payment_ref"])
        self.assertTrue(res.data["package_code"])
        self.assertTrue(res.data["settlement_plan"])
        self.assertTrue(ExpressOrder.objects.filter(public_code=res.data["public_code"]).exists())
