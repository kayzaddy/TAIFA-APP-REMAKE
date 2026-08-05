"""Seed configurable brokerage domains + default commission rules."""
from __future__ import annotations

from django.core.management.base import BaseCommand

from enterprise.models import WorkflowDefinition

from winga.models import BrokerageDomain, CommissionKind, CommissionRule
from winga.services import ensure_default_workflow

DOMAINS = [
    ("retail", "Retail products", 500),
    ("wholesale", "Wholesale", 300),
    ("digital", "Digital products", 800),
    ("hotels", "Hotels", 1000),
    ("vacation_rentals", "Vacation rentals / Airbnb-style", 1200),
    ("flights", "Flights", 200),
    ("bus", "Bus tickets", 400),
    ("train", "Train tickets", 400),
    ("taxi", "Taxi", 1000),
    ("mobility", "Mobility", 800),
    ("vehicle_rentals", "Vehicle rentals", 700),
    ("equipment", "Equipment rentals", 700),
    ("construction", "Construction services", 500),
    ("professional", "Professional services", 1000),
    ("healthcare", "Healthcare appointments", 600),
    ("insurance", "Insurance", 1500),
    ("financial", "Financial products", 1000),
    ("education", "Education services", 800),
    ("agriculture", "Agricultural products", 400),
    ("logistics", "Logistics", 600),
    ("courier", "Courier", 500),
    ("events", "Events", 800),
    ("government", "Government services", 300),
    ("property", "Property listings", 1500),
    ("real_estate", "Real estate", 2000),
    ("employment", "Employment opportunities", 1000),
    ("general", "General brokerage", 500),
]


class Command(BaseCommand):
    help = "Seed Winga brokerage domains, workflow, and default commission rules"

    def handle(self, *args, **options):
        ensure_default_workflow()
        created = 0
        for code, name, bps in DOMAINS:
            domain, was_created = BrokerageDomain.objects.get_or_create(
                code=code,
                defaults={
                    "name": name,
                    "default_commission_bps": bps,
                    "workflow_definition_code": "winga.default_brokerage",
                    "active": True,
                },
            )
            if was_created:
                created += 1
            CommissionRule.objects.get_or_create(
                code=f"default-{code}",
                defaults={
                    "name": f"Default {name} commission",
                    "kind": CommissionKind.PERCENTAGE,
                    "domain": domain,
                    "bps": bps,
                    "priority": 500,
                    "active": True,
                },
            )
        self.stdout.write(
            self.style.SUCCESS(
                f"Winga seed complete: {created} new domains, "
                f"{BrokerageDomain.objects.count()} total, "
                f"workflow={WorkflowDefinition.objects.filter(code='winga.default_brokerage').exists()}"
            )
        )
