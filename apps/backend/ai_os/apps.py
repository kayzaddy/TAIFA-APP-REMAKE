from django.apps import AppConfig


class AiOsConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "ai_os"
    label = "taifa_ai_os"
    verbose_name = "TAIFA AI Operating System"

    def ready(self):
        from . import signals  # noqa: F401
