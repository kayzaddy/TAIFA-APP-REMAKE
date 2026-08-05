from django.apps import AppConfig


class MobilityChannelsConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "mobility_channels"
    verbose_name = "Taifa Mobility Hybrid Dispatch"

    def ready(self):
        from . import metrics  # noqa: F401
