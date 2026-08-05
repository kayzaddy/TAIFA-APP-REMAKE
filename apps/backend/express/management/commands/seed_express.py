from django.core.management.base import BaseCommand

from express.models import ExpressProduct, ExpressStore, StoreCategory


SEED = [
    {
        "code": "xp-karibu-mart",
        "name": "Karibu Mart Masaki",
        "category": StoreCategory.GROCERIES,
        "lat": "-6.7450",
        "lng": "39.2800",
        "prep_minutes": 12,
        "rating": "4.70",
        "products": [
            ("MILK-1L", "Milk", 3500, 40, ["milk", "dairy", "breakfast"]),
            ("BREAD", "Bread", 2000, 30, ["bread", "bakery", "breakfast"]),
            ("EGGS-12", "Eggs", 6500, 25, ["eggs", "breakfast"]),
            ("RICE-5KG", "Rice", 18000, 20, ["rice", "dinner", "staples"]),
            ("SOAP", "Soap", 2500, 50, ["soap", "cleaning"]),
            ("SUGAR-1KG", "Sugar", 3200, 35, ["sugar", "tea"]),
            ("TEA", "Tea", 4500, 28, ["tea", "breakfast"]),
            ("FLOUR-2KG", "Flour", 5500, 22, ["flour", "chapati"]),
            ("OIL-1L", "Oil", 6000, 18, ["oil", "cooking", "chapati"]),
            ("SALT", "Salt", 800, 60, ["salt", "chapati"]),
            ("ONIONS", "Onions", 1500, 40, ["onions", "dinner", "chapati"]),
            ("TOMATOES", "Tomatoes", 2000, 35, ["tomatoes", "dinner"]),
            ("CHICKEN", "Chicken", 12000, 15, ["chicken", "dinner"]),
            ("BUTTER", "Butter", 4500, 20, ["butter", "breakfast"]),
            ("DETERGENT", "Detergent", 8000, 16, ["detergent", "cleaning"]),
            ("SPONGE", "Sponge", 1500, 40, ["sponge", "cleaning"]),
            ("DIAPERS", "Diapers", 22000, 12, ["diapers", "baby"]),
            ("WIPES", "Baby wipes", 6500, 14, ["wipes", "baby"]),
            ("FORMULA", "Formula", 35000, 8, ["formula", "baby"]),
        ],
    },
    {
        "code": "xp-afya-pharm",
        "name": "Afya Pharmacy Oysterbay",
        "category": StoreCategory.PHARMACY,
        "lat": "-6.7600",
        "lng": "39.2700",
        "prep_minutes": 8,
        "rating": "4.85",
        "products": [
            ("PARA-500", "Paracetamol", 2000, 80, ["pharmacy", "medicine"]),
            ("SOAP", "Soap", 2800, 40, ["soap", "hygiene"]),
            ("MASKS", "Face masks", 5000, 50, ["masks", "pharmacy"]),
        ],
    },
    {
        "code": "xp-fresh-veg",
        "name": "Fresh Veg Kariakoo",
        "category": StoreCategory.VEGETABLES,
        "lat": "-6.8200",
        "lng": "39.2800",
        "prep_minutes": 10,
        "rating": "4.40",
        "products": [
            ("ONIONS", "Onions", 1200, 100, ["onions", "vegetables"]),
            ("TOMATOES", "Tomatoes", 1800, 90, ["tomatoes", "vegetables"]),
            ("SPINACH", "Spinach", 1500, 40, ["spinach", "vegetables"]),
        ],
    },
]


class Command(BaseCommand):
    help = "Seed Taifa Express neighbourhood stores and inventory"

    def handle(self, *args, **options):
        created_stores = 0
        created_products = 0
        for row in SEED:
            store, was_created = ExpressStore.objects.update_or_create(
                code=row["code"],
                defaults={
                    "name": row["name"],
                    "category": row["category"],
                    "lat": row["lat"],
                    "lng": row["lng"],
                    "prep_minutes": row["prep_minutes"],
                    "rating": row["rating"],
                    "delivery_radius_m": 8000,
                    "verified": True,
                    "active": True,
                    "operating_hours": {"mon_sun": "07:00-21:00"},
                },
            )
            if was_created:
                created_stores += 1
            for sku, name, price, qty, tags in row["products"]:
                _, p_created = ExpressProduct.objects.update_or_create(
                    store=store,
                    sku=sku,
                    defaults={
                        "name": name,
                        "price_minor": price,
                        "stock_qty": qty,
                        "stock_status": "available",
                        "tags": tags,
                        "active": True,
                        "category": row["category"],
                    },
                )
                if p_created:
                    created_products += 1
        self.stdout.write(
            self.style.SUCCESS(
                f"Express seeded stores_new={created_stores} products_new={created_products} "
                f"total_stores={ExpressStore.objects.count()}"
            )
        )
