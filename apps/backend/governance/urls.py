from django.urls import path

from . import views

urlpatterns = [
    path("scorecard", views.ScorecardView.as_view(), name="governance-scorecard"),
    path("catalog", views.GovernanceCatalogView.as_view(), name="governance-catalog"),
]
