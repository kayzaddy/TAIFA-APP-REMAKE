from django.apps import AppConfig


class MobilityRegistryConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "mobility_registry"
    verbose_name = "TAIFA National Mobility Registry"

    def ready(self):
        from . import checks  # noqa: F401
