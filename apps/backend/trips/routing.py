from django.urls import path

from .consumers import TransitAvlConsumer, TripTrackingConsumer

websocket_urlpatterns = [
    path("ws/v1/mobility/trips/<uuid:trip_id>", TripTrackingConsumer.as_asgi()),
    path(
        "ws/v1/mobility/transit/live/<slug:region_slug>",
        TransitAvlConsumer.as_asgi(),
    ),
]
