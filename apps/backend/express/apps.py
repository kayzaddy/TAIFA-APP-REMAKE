from django.apps import AppConfig


class ExpressConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "express"
    verbose_name = "Taifa Express (Hyperlocal Commerce)"

    def ready(self):
        from . import metrics  # noqa: F401
