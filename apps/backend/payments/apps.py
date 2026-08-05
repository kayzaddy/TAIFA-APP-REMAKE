from django.apps import AppConfig


class PaymentsConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "payments"
    verbose_name = "TAIFA Payments"

    def ready(self):
        # Register production system checks.
        from . import production_gates  # noqa: F401
        from config import production_gates as platform_gates  # noqa: F401
