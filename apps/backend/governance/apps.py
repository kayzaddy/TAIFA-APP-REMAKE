from django.apps import AppConfig


class GovernanceConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "governance"
    label = "taifa_governance"
    verbose_name = "TAIFA Enterprise Governance"

    def ready(self):
        pass
