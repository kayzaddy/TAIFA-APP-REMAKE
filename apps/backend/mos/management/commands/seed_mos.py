"""Seed a demo Taifa Commerce merchant (idempotent)."""
from __future__ import annotations

from decimal import Decimal

from django.core.management.base import BaseCommand

from enterprise.models import Merchant, MerchantStatus

from mos import services
from mos.models import Product, ProductKind, StockMovementKind


class Command(BaseCommand):
    help = "Seed Taifa Commerce MOS demo merchant + catalog + stock"

    def handle(self, *args, **options):
        merchant, _ = Merchant.objects.update_or_create(
            code="taifa-demo-retail",
            defaults={
                "legal_name": "Taifa Demo Retail Ltd",
                "trading_name": "Taifa Mart",
                "status": MerchantStatus.ACTIVE,
                "sector": "retail",
                "owner_principal": "mos:demo",
            },
        )
        cm, branch, wh = services.bootstrap_merchant_ops(
            merchant=merchant, business_type="retail", hq_name="Kariakoo HQ"
        )
        products = [
            ("RICE-5KG", "Rice 5kg", 12000, 9000),
            ("OIL-1L", "Cooking Oil 1L", 6500, 4800),
            ("SOAP-BAR", "Bar Soap", 1500, 800),
        ]
        for sku, name, price, cost in products:
            product, _ = Product.objects.update_or_create(
                commerce_merchant=cm,
                sku=sku,
                defaults={
                    "name": name,
                    "kind": ProductKind.PHYSICAL,
                    "price_minor": price,
                    "cost_minor": cost,
                    "track_inventory": True,
                    "active": True,
                },
            )
            stock = services.get_or_create_stock(warehouse=wh, product=product)
            if stock.on_hand < 20:
                services.adjust_stock(
                    stock_item=stock,
                    kind=StockMovementKind.RECEIVE,
                    quantity=Decimal("50"),
                    actor="seed",
                    note="seed_mos",
                )
        self.stdout.write(
            self.style.SUCCESS(
                f"MOS seed OK merchant={merchant.code} products={cm.products.count()} "
                f"branch={branch.code} warehouse={wh.code}"
            )
        )
