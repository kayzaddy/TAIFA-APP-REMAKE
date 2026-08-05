from django.core.management.base import BaseCommand

from ecosystem.services import seed_ecosystem_catalog


class Command(BaseCommand):
    help = "Seed Taifa Digital Ecosystem catalog (domains, modules, workflows, AI)."

    def handle(self, *args, **options):
        result = seed_ecosystem_catalog()
        self.stdout.write(self.style.SUCCESS(f"Seeded: {result}"))
