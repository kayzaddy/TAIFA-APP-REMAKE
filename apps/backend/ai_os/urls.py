from django.urls import path

from . import views

urlpatterns = [
    path("command-center", views.CommandCenterView.as_view(), name="ai-os-command-center"),
    path("capabilities", views.CapabilityListView.as_view(), name="ai-os-capabilities"),
    path("infer/<slug:capability_code>", views.InferView.as_view(), name="ai-os-infer"),
    path("agents", views.AgentListView.as_view(), name="ai-os-agents"),
    path("agents/<slug:agent_code>/run", views.AgentRunView.as_view(), name="ai-os-agent-run"),
    path("knowledge", views.KnowledgeListView.as_view(), name="ai-os-knowledge"),
    path("knowledge/search", views.KnowledgeSearchView.as_view(), name="ai-os-knowledge-search"),
    path(
        "automations/<slug:rule_code>/run",
        views.AutomationRunView.as_view(),
        name="ai-os-automation-run",
    ),
    path("decisions/<uuid:decision_id>", views.DecisionDetailView.as_view(), name="ai-os-decision"),
    path(
        "decisions/<uuid:decision_id>/approve",
        views.DecisionApprovalView.as_view(),
        name="ai-os-decision-approve",
    ),
    path("registry", views.ModelRegistryView.as_view(), name="ai-os-registry"),
    path("features", views.FeatureStoreView.as_view(), name="ai-os-features"),
    path("seed", views.SeedAiOsView.as_view(), name="ai-os-seed"),
]
