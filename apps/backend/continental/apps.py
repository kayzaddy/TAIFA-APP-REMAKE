from django.apps import AppConfig


class ContinentalConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "continental"
    label = "taifa_continental"
    verbose_name = "TAIFA Pan-African Continental Platform"

    def ready(self):
        from . import signals  # noqa: F401
