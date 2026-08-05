from django.urls import path

from . import views

urlpatterns = [
    path("blueprint", views.EcosystemBlueprintView.as_view(), name="platform-blueprint"),
    path("services", views.SharedServiceListView.as_view(), name="platform-services"),
    path("domains", views.DomainListView.as_view(), name="platform-domains"),
    path("modules", views.MyModulesView.as_view(), name="platform-modules"),
    path(
        "modules/<slug:module_code>/enable",
        views.ModuleEnableView.as_view(),
        name="platform-module-enable",
    ),
    path("workflows", views.WorkflowBindingListView.as_view(), name="platform-workflows"),
    path("workflows/start", views.WorkflowStartView.as_view(), name="platform-workflow-start"),
    path(
        "workflows/<uuid:instance_id>/advance",
        views.WorkflowAdvanceView.as_view(),
        name="platform-workflow-advance",
    ),
    path("ai/capabilities", views.AiCapabilityListView.as_view(), name="platform-ai-caps"),
    path(
        "ai/<slug:capability_code>/invoke",
        views.AiInvokeView.as_view(),
        name="platform-ai-invoke",
    ),
    path("webhooks", views.WebhookSubscribeView.as_view(), name="platform-webhooks"),
    path("partners/apply", views.PartnerApplyView.as_view(), name="platform-partner-apply"),
    path("open/catalog", views.OpenCatalogView.as_view(), name="platform-open-catalog"),
    path("observability", views.ObservabilityView.as_view(), name="platform-observability"),
    path("agriculture/farms", views.AgricultureFarmView.as_view(), name="platform-ag-farms"),
    path(
        "agriculture/listings",
        views.AgricultureListingView.as_view(),
        name="platform-ag-listings",
    ),
    path("catalog/seed", views.SeedCatalogView.as_view(), name="platform-catalog-seed"),
]
