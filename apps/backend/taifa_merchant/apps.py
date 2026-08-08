from django.apps import AppConfig


class TaifaMerchantConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "taifa_merchant"
    verbose_name = "Taifa Merchant App"

    def ready(self) -> None:
        from taifa_merchant.infrastructure.events import handlers  # noqa: F401
        from taifa_merchant.infrastructure import payment_models  # noqa: F401
