from django.urls import path

from . import views

urlpatterns = [
    path("webhooks/sms/inbound", views.SmsInboundWebhookView.as_view(), name="hybrid-sms-inbound"),
    path("webhooks/ussd", views.UssdCallbackView.as_view(), name="hybrid-ussd"),
    path("webhooks/ivr/dtmf", views.IvrDtmfWebhookView.as_view(), name="hybrid-ivr"),
    path("drivers/bind", views.DriverBindingView.as_view(), name="hybrid-driver-bind"),
    path("trips/<uuid:trip_id>/verify-pin", views.TripBoardingPinVerifyView.as_view()),
    path("trips/<uuid:trip_id>/status", views.TripHybridStatusView.as_view()),
    path("trips/<uuid:trip_id>/dispatch-detail", views.TripDispatchDetailView.as_view()),
    path(
        "trips/<uuid:trip_id>/simulate-sms-accept",
        views.SimulateFeaturePhoneSmsView.as_view(),
        name="hybrid-simulate-sms",
    ),
    path(
        "stations/<uuid:station_id>/dispatch",
        views.StationManualDispatchView.as_view(),
        name="hybrid-station-dispatch",
    ),
]
