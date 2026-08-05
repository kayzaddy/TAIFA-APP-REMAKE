from django.urls import path

from . import views

app_name = "mobility_registry"

urlpatterns = [
    path("applications", views.ApplicationListView.as_view(), name="applications"),
    path("applications/drivers", views.DriverRegistrationView.as_view(), name="register-driver"),
    path("applications/vehicles", views.VehicleRegistrationView.as_view(), name="register-vehicle"),
    path("applications/stations", views.StationRegistrationView.as_view(), name="register-station"),
    path("applications/fleets", views.FleetRegistrationView.as_view(), name="register-fleet"),
    path(
        "applications/<uuid:application_id>",
        views.ApplicationDetailView.as_view(),
        name="application-detail",
    ),
    path(
        "applications/<uuid:application_id>/submit",
        views.SubmitApplicationView.as_view(),
        name="application-submit",
    ),
    path(
        "applications/<uuid:application_id>/documents",
        views.DocumentListView.as_view(),
        name="documents",
    ),
    path(
        "applications/<uuid:application_id>/documents/upload",
        views.DocumentUploadView.as_view(),
        name="document-upload",
    ),
    path(
        "applications/<uuid:application_id>/workflow/<str:action>",
        views.WorkflowActionView.as_view(),
        name="workflow-action",
    ),
    path(
        "applications/<uuid:application_id>/external-verification",
        views.ExternalVerificationView.as_view(),
        name="external-verification",
    ),
    path(
        "applications/<uuid:application_id>/audit",
        views.ApplicationAuditView.as_view(),
        name="application-audit",
    ),
    path(
        "documents/<uuid:document_id>/download",
        views.DocumentDownloadView.as_view(),
        name="document-download",
    ),
    path(
        "documents/<uuid:document_id>/review",
        views.DocumentReviewView.as_view(),
        name="document-review",
    ),
    path(
        "verification/dashboard",
        views.VerificationDashboardView.as_view(),
        name="verification-dashboard",
    ),
    path(
        "compliance/dashboard",
        views.ComplianceDashboardView.as_view(),
        name="compliance-dashboard",
    ),
    path("compliance/blacklist", views.BlacklistCreateView.as_view(), name="blacklist-create"),
    path("verification/queue", views.VerificationQueueView.as_view(), name="verification-queue"),
    path("search", views.RegistrySearchView.as_view(), name="search"),
]
