from django.apps import AppConfig


class EcosystemConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "ecosystem"
    label = "taifa_ecosystem"
    verbose_name = "TAIFA Digital Ecosystem Platform"

    def ready(self):
        from . import signals  # noqa: F401
