from django.core.management.base import BaseCommand

from continental.services import seed_continental


class Command(BaseCommand):
    help = "Seed Pan-African country profiles, FX, compliance, corridors, partners."

    def handle(self, *args, **options):
        result = seed_continental()
        self.stdout.write(self.style.SUCCESS(f"Seeded continental: {result}"))
