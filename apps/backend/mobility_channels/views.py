"""Hybrid dispatch HTTP — SMS/USSD/IVR webhooks + station tools."""
from __future__ import annotations

from django.shortcuts import get_object_or_404
from rest_framework.response import Response
from rest_framework.views import APIView

from payments.auth import IsDevice
from trips.models import Station, Trip
from trips.services import MobilityError, dispatch_trip

from . import services
from .models import DriverChannelBinding
from .serializers import (
    ChannelBindingSerializer,
    TripBoardingPinVerifySerializer,
    TripDispatchDetailSerializer,
    TripStatusSerializer,
)


class SmsInboundWebhookView(APIView):
    """Inbound SMS from aggregator (Africa's Talking, Twilio, etc.)."""

    authentication_classes = []
    permission_classes = []

    def post(self, request):
        msisdn = (
            request.data.get("from")
            or request.data.get("msisdn")
            or request.data.get("phone")
            or ""
        )
        body = request.data.get("text") or request.data.get("body") or request.data.get("message") or ""
        if not msisdn:
            return Response({"detail": "from/msisdn required"}, status=400)
        result = services.handle_inbound_sms(msisdn=str(msisdn), body=str(body))
        return Response(result)


class UssdCallbackView(APIView):
    authentication_classes = []
    permission_classes = []

    def post(self, request):
        msisdn = request.data.get("phoneNumber") or request.data.get("msisdn") or ""
        text = request.data.get("text") or request.data.get("ussd") or ""
        if not msisdn:
            return Response({"detail": "msisdn required"}, status=400)
        response_text = services.handle_ussd(msisdn=str(msisdn), text=str(text))
        return Response({"response": response_text})


class IvrDtmfWebhookView(APIView):
    authentication_classes = []
    permission_classes = []

    def post(self, request):
        offer_id = request.data.get("offer_id") or ""
        digit = str(request.data.get("digit") or request.data.get("dtmf") or "")
        if not offer_id or not digit:
            return Response({"detail": "offer_id and digit required"}, status=400)
        result = services.handle_ivr_dtmf(offer_id=offer_id, digit=digit)
        return Response(result)


class DriverBindingView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        driver_id = request.data.get("driver_id")
        if not driver_id:
            return Response({"detail": "driver_id required"}, status=400)
        from trips.models import Driver

        driver = get_object_or_404(Driver, pk=driver_id)
        binding = services.ensure_binding(
            driver=driver,
            msisdn=str(request.data.get("msisdn") or ""),
            device_capability=request.data.get("device_capability") or "smartphone",
            has_internet=bool(request.data.get("has_internet", True)),
            has_gps=bool(request.data.get("has_gps", True)),
            push_token=str(request.data.get("push_token") or ""),
        )
        return Response(ChannelBindingSerializer(binding).data, status=201)


class TripBoardingPinVerifyView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, trip_id):
        serializer = TripBoardingPinVerifySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        trip = get_object_or_404(Trip, pk=trip_id)
        pin = serializer.validated_data["pin"]
        ok = services.verify_boarding_pin(
            trip=trip,
            pin=pin,
            actor=getattr(request, "device_id", "device"),
        )
        if not ok:
            return Response({"detail": "invalid pin"}, status=403)
        return Response({"verified": True})


class TripHybridStatusView(APIView):
    """Passenger-friendly hybrid dispatch status (channel opaque)."""

    permission_classes = [IsDevice]

    def get(self, request, trip_id):
        trip = get_object_or_404(Trip, pk=trip_id, owner=request.auth.owner)
        return Response(
            TripStatusSerializer(
                {
                    "trip_id": str(trip.id),
                    "status": trip.status,
                    "message": services.passenger_status_message(trip),
                    "driver_name": trip.driver_name,
                    "vehicle_label": trip.vehicle_label,
                }
            ).data
        )


class TripDispatchDetailView(APIView):
    """Demo: show SMS offer preview and channel attempts for a trip."""

    permission_classes = [IsDevice]

    def get(self, request, trip_id):
        trip = get_object_or_404(Trip, pk=trip_id, owner=request.auth.owner)
        return Response(TripDispatchDetailSerializer(services.trip_dispatch_detail(trip=trip)).data)


class SimulateFeaturePhoneSmsView(APIView):
    """Demo: simulate feature-phone driver replying YES via SMS."""

    permission_classes = [IsDevice]

    def post(self, request, trip_id):
        trip = get_object_or_404(Trip, pk=trip_id, owner=request.auth.owner)
        result = services.simulate_feature_phone_sms_accept(trip=trip)
        return Response(result)


class StationManualDispatchView(APIView):
    """Stage dispatcher manual dispatch trigger."""

    permission_classes = [IsDevice]

    def post(self, request, station_id):
        station = get_object_or_404(Station, pk=station_id)
        trip_id = request.data.get("trip_id")
        if not trip_id:
            return Response({"detail": "trip_id required"}, status=400)
        trip = get_object_or_404(Trip, pk=trip_id, station=station)
        try:
            offers = dispatch_trip(trip.id, actor=getattr(request, "device_id", "station"))
        except MobilityError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response({"offers": len(offers), "trip_id": str(trip.id)})
