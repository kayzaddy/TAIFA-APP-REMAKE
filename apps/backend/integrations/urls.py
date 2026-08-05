from django.urls import path

from .views import IntegrationCatalogView, IntegrationCertificationView, IntegrationHealthView

urlpatterns = [
    path("catalog", IntegrationCatalogView.as_view(), name="integrations-catalog"),
    path("certification", IntegrationCertificationView.as_view(), name="integrations-certification"),
    path("health", IntegrationHealthView.as_view(), name="integrations-health"),
]
