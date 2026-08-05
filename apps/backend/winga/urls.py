from django.urls import path

from . import views

urlpatterns = [
    path("domains", views.DomainListView.as_view(), name="winga-domains"),
    path("categories", views.CategoryListView.as_view(), name="winga-categories"),
    path("wingas", views.WingaProfileListCreateView.as_view(), name="winga-profiles"),
    path("wingas/<uuid:pk>/verify", views.WingaVerifyView.as_view(), name="winga-verify"),
    path("providers", views.ProviderListCreateView.as_view(), name="winga-providers"),
    path("providers/<uuid:pk>/verify", views.ProviderVerifyView.as_view(), name="winga-provider-verify"),
    path("offerings", views.OfferingListCreateView.as_view(), name="winga-offerings"),
    path("leads", views.LeadListCreateView.as_view(), name="winga-leads"),
    path("quotations", views.QuotationCreateView.as_view(), name="winga-quotations"),
    path("deals", views.DealListCreateView.as_view(), name="winga-deals"),
    path("deals/<uuid:pk>", views.DealDetailView.as_view(), name="winga-deal-detail"),
    path("deals/<uuid:pk>/advance", views.DealAdvanceView.as_view(), name="winga-deal-advance"),
    path("deals/<uuid:pk>/pay", views.DealPayView.as_view(), name="winga-deal-pay"),
    path(
        "deals/<uuid:pk>/settle-commission",
        views.DealSettleCommissionView.as_view(),
        name="winga-deal-settle-commission",
    ),
    path("commission-rules", views.CommissionRuleListCreateView.as_view(), name="winga-commission-rules"),
    path("commission-events", views.CommissionEventListView.as_view(), name="winga-commission-events"),
    path("reviews", views.ReviewCreateView.as_view(), name="winga-reviews"),
    path("favorites", views.FavoriteListCreateView.as_view(), name="winga-favorites"),
    path("assist", views.AssistView.as_view(), name="winga-assist"),
    path("analytics/summary", views.AnalyticsSummaryView.as_view(), name="winga-analytics"),
]
