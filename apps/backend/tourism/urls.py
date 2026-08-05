from django.urls import path

from . import views

urlpatterns = [
    path("trips", views.TourismTripListCreateView.as_view(), name="tourism-trips"),
    path("trips/<uuid:trip_id>", views.TourismTripDetailView.as_view(), name="tourism-trip-detail"),
    path("trips/<uuid:trip_id>/plan", views.TourismTripPlanView.as_view(), name="tourism-trip-plan"),
    path(
        "trips/<uuid:trip_id>/itineraries",
        views.TourismTripItinerariesView.as_view(),
        name="tourism-trip-itineraries",
    ),
    path(
        "trips/<uuid:trip_id>/itineraries/<uuid:itinerary_id>/select",
        views.TourismTripSelectItineraryView.as_view(),
        name="tourism-trip-select-itinerary",
    ),
    path(
        "trips/<uuid:trip_id>/attach-booking",
        views.TourismTripAttachBookingView.as_view(),
        name="tourism-trip-attach-booking",
    ),
    path(
        "trips/<uuid:trip_id>/cart/build",
        views.TourismTripCartBuildView.as_view(),
        name="tourism-trip-cart-build",
    ),
    path(
        "trips/<uuid:trip_id>/checkout",
        views.TourismTripCheckoutView.as_view(),
        name="tourism-trip-checkout",
    ),
    path(
        "trips/<uuid:trip_id>/checkout/pay",
        views.TourismTripCheckoutPayView.as_view(),
        name="tourism-trip-checkout-pay",
    ),
    path("connectivity/esim/plans", views.TourismEsimPlansView.as_view(), name="tourism-esim-plans"),
    path("connectivity/esim/quote", views.TourismEsimQuoteView.as_view(), name="tourism-esim-quote"),
    path(
        "connectivity/esim/<uuid:order_id>/qr",
        views.TourismEsimQrView.as_view(),
        name="tourism-esim-qr",
    ),
    path("assist/nearby", views.TourismAssistNearbyView.as_view(), name="tourism-assist-nearby"),
    path("assist/sos", views.TourismAssistSosView.as_view(), name="tourism-assist-sos"),
]
