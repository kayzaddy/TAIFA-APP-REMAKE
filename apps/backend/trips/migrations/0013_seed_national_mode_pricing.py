# Seed pricing for Phase 3 national transport modes / trip kinds.

import django.utils.timezone
from django.db import migrations


def seed_national_pricing(apps, schema_editor):
    PricingRule = apps.get_model("trips", "PricingRule")
    now = django.utils.timezone.now()
    # (mode, trip_kind, base, per_km, per_minute, minimum)
    rules = [
        ("minibus", "passenger", 120_000, 40_000, 1_000, 120_000),
        ("delivery_bike", "delivery", 80_000, 40_000, 800, 80_000),
        ("delivery_bike", "passenger", 80_000, 40_000, 800, 80_000),
        ("ambulance", "emergency", 0, 0, 0, 0),
        ("ambulance", "passenger", 0, 0, 0, 0),
        ("school_bus", "passenger", 50_000, 20_000, 500, 50_000),
        ("van", "emergency", 0, 0, 0, 0),
        ("van", "delivery", 400_000, 150_000, 3_000, 600_000),
        ("truck", "delivery", 1_000_000, 300_000, 5_000, 1_500_000),
        ("bus", "passenger", 100_000, 30_000, 1_000, 100_000),
        ("motorcycle", "delivery", 80_000, 40_000, 800, 80_000),
        ("motorcycle", "emergency", 0, 0, 0, 0),
    ]
    for mode, kind, base, per_km, per_minute, minimum in rules:
        PricingRule.objects.get_or_create(
            code=f"tz-{mode}-{kind}-national",
            version=1,
            defaults={
                "vehicle_mode": mode,
                "region": "",
                "trip_kind": kind,
                "base_fare_minor": base,
                "per_km_minor": per_km,
                "per_minute_minor": per_minute,
                "waiting_per_minute_minor": per_minute,
                "station_fee_minor": 0,
                "night_multiplier_e4": 10000,
                "peak_multiplier_e4": 10000,
                "minimum_fare_minor": minimum,
                "conditions": {},
                "active": True,
                "effective_from": now,
            },
        )


class Migration(migrations.Migration):
    dependencies = [
        ("trips", "0012_national_mobility_infrastructure"),
    ]

    operations = [
        migrations.RunPython(seed_national_pricing, migrations.RunPython.noop),
    ]
