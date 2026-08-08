from django.contrib import admin
from django.urls import include, path
from drf_spectacular.views import (
    SpectacularAPIView,
    SpectacularRedocView,
    SpectacularSwaggerView,
)
from rest_framework.permissions import AllowAny

from config.health import (
    dependencies_payload,
    json_probe,
    liveness_payload,
    readiness_payload,
    startup_payload,
)
from payments.metrics import metrics_view
from payments.people_views import DeviceProfileView, MerchantStatusView
from payments.views import DevicePushTokenView, DeviceRegisterView


def healthz(_request):
    """Liveness: the process is up and serving."""
    return json_probe(liveness_payload())


def readyz(_request):
    """Readiness: critical dependencies reachable."""
    payload, status = readiness_payload()
    return json_probe(payload, status=status)


def startupz(_request):
    """Startup: migrations applied and core modules importable."""
    payload, status = startup_payload()
    return json_probe(payload, status=status)


def depsz(_request):
    """Dependency health: full subsystem report for operators."""
    payload, status = dependencies_payload()
    return json_probe(payload, status=status)


urlpatterns = [
    path("healthz", healthz),
    path("readyz", readyz),
    path("startupz", startupz),
    path("depsz", depsz),
    path("metrics", metrics_view),
    path("admin/", admin.site.urls),
    # API contract: machine-readable schema + human-browsable docs.
    path(
        "api/schema",
        SpectacularAPIView.as_view(permission_classes=[AllowAny]),
        name="schema",
    ),
    path(
        "api/docs",
        SpectacularSwaggerView.as_view(url_name="schema", permission_classes=[AllowAny]),
        name="swagger-ui",
    ),
    path(
        "api/redoc",
        SpectacularRedocView.as_view(url_name="schema", permission_classes=[AllowAny]),
        name="redoc",
    ),
    path("api/v1/auth/device/register", DeviceRegisterView.as_view(), name="device-register"),
    path("api/v1/auth/device/push-token", DevicePushTokenView.as_view(), name="device-push-token"),
    path("api/v1/auth/device/profile", DeviceProfileView.as_view(), name="device-profile"),
    path("api/v1/auth/device/merchant", MerchantStatusView.as_view(), name="device-merchant"),
    path("api/v1/payments/", include("payments.urls")),
    path("api/v1/enterprise/", include("enterprise.urls")),
    path("api/v1/mobility-registry/", include("mobility_registry.urls")),
    path("api/v1/trips/", include("trips.urls")),
    path("api/v1/commerce/", include("commerce.urls")),
    path("api/v1/tourism/", include("tourism.urls")),
    path("api/v1/ecosystem/", include("ecosystem.urls")),
    path("api/v1/ai-os/", include("ai_os.urls")),
    path("api/v1/continental/", include("continental.urls")),
    path("api/v1/governance/", include("governance.urls")),
    path("api/v1/integrations/", include("integrations.urls")),
    path("api/v1/winga/", include("winga.urls")),
    path("api/v1/winga-property/", include("winga_property.urls")),
    path("api/v1/mos/", include("mos.urls")),
    path("api/v1/map/", include("acceptance.urls")),
    path("api/v1/express/", include("express.urls")),
    path("api/v1/mobility-channels/", include("mobility_channels.urls")),
    path("api/v1/merchant-app/", include("taifa_merchant.urls")),
]
