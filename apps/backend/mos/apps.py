from django.apps import AppConfig


class MosConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "mos"
    verbose_name = "Taifa Commerce (Merchant Operating System)"

    def ready(self):
        from . import metrics  # noqa: F401
