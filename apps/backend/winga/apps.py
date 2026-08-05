from django.apps import AppConfig


class WingaConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "winga"
    verbose_name = "Taifa Winga Brokerage Platform"

    def ready(self):
        from . import metrics  # noqa: F401
