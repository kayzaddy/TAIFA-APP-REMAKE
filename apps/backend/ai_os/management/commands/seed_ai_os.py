from django.core.management.base import BaseCommand

from ai_os.services import seed_ai_os


class Command(BaseCommand):
    help = "Seed Taifa AI OS models, capabilities, agents, and knowledge."

    def handle(self, *args, **options):
        result = seed_ai_os()
        self.stdout.write(self.style.SUCCESS(f"Seeded AI OS: {result}"))
