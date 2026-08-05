from django.urls import path

from . import views

urlpatterns = [
    path("blueprint", views.BlueprintView.as_view(), name="continental-blueprint"),
    path("countries", views.CountryListView.as_view(), name="continental-countries"),
    path(
        "countries/<str:country_code>",
        views.CountryDetailView.as_view(),
        name="continental-country",
    ),
    path("ops-center", views.OpsCenterView.as_view(), name="continental-ops"),
    path("fx/quote", views.FxQuoteView.as_view(), name="continental-fx"),
    path("corridors", views.CorridorListView.as_view(), name="continental-corridors"),
    path(
        "cross-border/quote",
        views.CrossBorderQuoteView.as_view(),
        name="continental-xborder-quote",
    ),
    path(
        "compliance/evaluate",
        views.ComplianceEvaluateView.as_view(),
        name="continental-compliance",
    ),
    path(
        "identity/<str:country_code>/lookup",
        views.IdentityLookupView.as_view(),
        name="continental-identity",
    ),
    path("i18n/<str:locale>", views.LanguagePackView.as_view(), name="continental-i18n"),
    path("i18n/translate", views.TranslateView.as_view(), name="continental-translate"),
    path("partners", views.PartnerListView.as_view(), name="continental-partners"),
    path("seed", views.SeedView.as_view(), name="continental-seed"),
]
