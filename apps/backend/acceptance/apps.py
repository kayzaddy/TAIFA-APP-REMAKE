from django.apps import AppConfig


class AcceptanceConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "acceptance"
    verbose_name = "Taifa Merchant Acceptance Platform (MAP)"

    def ready(self):
        from . import metrics  # noqa: F401
