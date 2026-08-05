from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from payments.auth import IsDevice

from .assist_services import (
    assistance_case_to_dict,
    nearby_assistance,
    open_tourism_sos,
)
from .models import TourismEsimOrder, TourismTrip
from .serializers import (
    TourismAssistSosSerializer,
    TourismAttachBookingSerializer,
    TourismCartBuildSerializer,
    TourismCheckoutCreateSerializer,
    TourismEsimQuoteSerializer,
    TourismTripCreateSerializer,
    TourismTripPlanSerializer,
)
from .services import (
    TourismError,
    attach_booking,
    build_trip_cart,
    checkout_to_dict,
    create_trip,
    create_trip_checkout,
    esim_order_to_dict,
    esim_quote,
    itinerary_to_dict,
    list_esim_plans,
    pay_trip_checkout,
    plan_trip,
    select_itinerary,
    trip_to_dict,
)


class TourismTripListCreateView(APIView):
    permission_classes = [IsDevice]

    @extend_schema(tags=["tourism"], operation_id="tourism_trips_list")
    def get(self, request):
        qs = TourismTrip.objects.filter(owner=request.auth.owner)[:30]
        return Response(
            {
                "trips": [trip_to_dict(t) for t in qs],
                "model_version": "tourism.trip.list.v1",
            }
        )

    @extend_schema(tags=["tourism"], operation_id="tourism_trips_create")
    def post(self, request):
        s = TourismTripCreateSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        trip = create_trip(owner=request.auth.owner, **s.validated_data)
        return Response(trip_to_dict(trip), status=status.HTTP_201_CREATED)


class TourismTripDetailView(APIView):
    permission_classes = [IsDevice]

    def _get(self, request, trip_id):
        try:
            return TourismTrip.objects.get(pk=trip_id, owner=request.auth.owner)
        except TourismTrip.DoesNotExist:
            return None

    @extend_schema(tags=["tourism"], operation_id="tourism_trips_retrieve")
    def get(self, request, trip_id):
        trip = self._get(request, trip_id)
        if trip is None:
            return Response({"detail": "not found"}, status=status.HTTP_404_NOT_FOUND)
        return Response(trip_to_dict(trip))


class TourismTripPlanView(APIView):
    permission_classes = [IsDevice]

    @extend_schema(tags=["tourism"], operation_id="tourism_trips_plan")
    def post(self, request, trip_id):
        try:
            trip = TourismTrip.objects.get(pk=trip_id, owner=request.auth.owner)
        except TourismTrip.DoesNotExist:
            return Response({"detail": "not found"}, status=status.HTTP_404_NOT_FOUND)
        s = TourismTripPlanSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        trip, itineraries = plan_trip(trip=trip, **s.validated_data)
        return Response(
            {
                "trip": trip_to_dict(trip),
                "itineraries": [itinerary_to_dict(i) for i in itineraries],
                "model_version": "tourism.plan.v1",
            }
        )


class TourismTripItinerariesView(APIView):
    permission_classes = [IsDevice]

    @extend_schema(tags=["tourism"], operation_id="tourism_trips_itineraries_list")
    def get(self, request, trip_id):
        try:
            trip = TourismTrip.objects.get(pk=trip_id, owner=request.auth.owner)
        except TourismTrip.DoesNotExist:
            return Response({"detail": "not found"}, status=status.HTTP_404_NOT_FOUND)
        rows = trip.itineraries.all()
        return Response(
            {
                "trip_id": str(trip.id),
                "itineraries": [itinerary_to_dict(i) for i in rows],
            }
        )


class TourismTripSelectItineraryView(APIView):
    permission_classes = [IsDevice]

    @extend_schema(tags=["tourism"], operation_id="tourism_trips_select_itinerary")
    def post(self, request, trip_id, itinerary_id):
        try:
            trip = TourismTrip.objects.get(pk=trip_id, owner=request.auth.owner)
        except TourismTrip.DoesNotExist:
            return Response({"detail": "not found"}, status=status.HTTP_404_NOT_FOUND)
        try:
            trip = select_itinerary(trip=trip, itinerary_id=itinerary_id)
        except TourismError as e:
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)
        return Response(trip_to_dict(trip))


class TourismTripAttachBookingView(APIView):
    permission_classes = [IsDevice]

    @extend_schema(tags=["tourism"], operation_id="tourism_trips_attach_booking")
    def post(self, request, trip_id):
        try:
            trip = TourismTrip.objects.get(pk=trip_id, owner=request.auth.owner)
        except TourismTrip.DoesNotExist:
            return Response({"detail": "not found"}, status=status.HTTP_404_NOT_FOUND)
        s = TourismAttachBookingSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        try:
            trip = attach_booking(
                trip=trip,
                booking_type=s.validated_data["booking_type"],
                booking_id=str(s.validated_data["booking_id"]),
            )
        except TourismError as e:
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)
        return Response(trip_to_dict(trip))


class TourismTripCartBuildView(APIView):
    permission_classes = [IsDevice]

    @extend_schema(tags=["tourism"], operation_id="tourism_trips_cart_build")
    def post(self, request, trip_id):
        try:
            trip = TourismTrip.objects.get(pk=trip_id, owner=request.auth.owner)
        except TourismTrip.DoesNotExist:
            return Response({"detail": "not found"}, status=status.HTTP_404_NOT_FOUND)
        s = TourismCartBuildSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        cart = build_trip_cart(
            trip=trip,
            include_insurance_quote=s.validated_data.get("include_insurance_quote", True),
            include_esim_quote=s.validated_data.get("include_esim_quote", True),
            esim_plan_id=s.validated_data.get("esim_plan_id", "esim-7d-5gb"),
        )
        return Response(cart)


class TourismTripCheckoutView(APIView):
    permission_classes = [IsDevice]

    @extend_schema(tags=["tourism"], operation_id="tourism_trips_checkout_create")
    def post(self, request, trip_id):
        try:
            trip = TourismTrip.objects.get(pk=trip_id, owner=request.auth.owner)
        except TourismTrip.DoesNotExist:
            return Response({"detail": "not found"}, status=status.HTTP_404_NOT_FOUND)
        s = TourismCheckoutCreateSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        try:
            _checkout, payload = create_trip_checkout(
                trip=trip,
                include_insurance=s.validated_data.get("include_insurance", False),
                insurance_plan_id=s.validated_data.get("insurance_plan_id", "ins-travel"),
                include_esim=s.validated_data.get("include_esim", False),
                esim_plan_id=s.validated_data.get("esim_plan_id", "esim-7d-5gb"),
            )
        except TourismError as e:
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)
        return Response(payload, status=status.HTTP_201_CREATED)


class TourismTripCheckoutPayView(APIView):
    permission_classes = [IsDevice]

    @extend_schema(tags=["tourism"], operation_id="tourism_trips_checkout_pay")
    def post(self, request, trip_id):
        try:
            trip = TourismTrip.objects.get(pk=trip_id, owner=request.auth.owner)
        except TourismTrip.DoesNotExist:
            return Response({"detail": "not found"}, status=status.HTTP_404_NOT_FOUND)
        key = request.headers.get("Idempotency-Key", "").strip()
        if not key:
            return Response({"detail": "Idempotency-Key required"}, status=400)
        try:
            checkout = pay_trip_checkout(
                trip=trip,
                owner=request.auth.owner,
                actor=request.auth.owner,
                idempotency_key=key,
            )
        except TourismError as e:
            return Response({"detail": str(e)}, status=status.HTTP_409_CONFLICT)
        return Response(checkout_to_dict(checkout))


class TourismEsimPlansView(APIView):
    permission_classes = [IsDevice]

    @extend_schema(tags=["tourism"], operation_id="tourism_esim_plans_list")
    def get(self, request):
        return Response({"plans": list_esim_plans(), "model_version": "tourism.esim.plans.v1"})


class TourismEsimQuoteView(APIView):
    permission_classes = [IsDevice]

    @extend_schema(tags=["tourism"], operation_id="tourism_esim_quote")
    def post(self, request):
        s = TourismEsimQuoteSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        quote = esim_quote(plan_id=s.validated_data.get("plan_id", "esim-7d-5gb"))
        if quote is None:
            return Response({"detail": "plan not found"}, status=status.HTTP_404_NOT_FOUND)
        return Response(quote)


class TourismEsimQrView(APIView):
    permission_classes = [IsDevice]

    @extend_schema(tags=["tourism"], operation_id="tourism_esim_qr")
    def get(self, request, order_id):
        try:
            order = TourismEsimOrder.objects.get(pk=order_id, owner=request.auth.owner)
        except TourismEsimOrder.DoesNotExist:
            return Response({"detail": "not found"}, status=status.HTTP_404_NOT_FOUND)
        return Response(
            {
                "order": esim_order_to_dict(order),
                "qr_payload": order.qr_payload,
                "model_version": "tourism.esim.qr.v1",
            }
        )


class TourismAssistNearbyView(APIView):
    permission_classes = [IsDevice]

    @extend_schema(tags=["tourism"], operation_id="tourism_assist_nearby")
    def get(self, request):
        lat = request.query_params.get("lat")
        lng = request.query_params.get("lng")
        latitude = float(lat) if lat else None
        longitude = float(lng) if lng else None
        return Response(nearby_assistance(latitude=latitude, longitude=longitude))


class TourismAssistSosView(APIView):
    permission_classes = [IsDevice]

    @extend_schema(tags=["tourism"], operation_id="tourism_assist_sos")
    def post(self, request):
        s = TourismAssistSosSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        trip = None
        trip_id = s.validated_data.get("trip_id")
        if trip_id:
            try:
                trip = TourismTrip.objects.get(pk=trip_id, owner=request.auth.owner)
            except TourismTrip.DoesNotExist:
                return Response({"detail": "trip not found"}, status=status.HTTP_404_NOT_FOUND)
        case = open_tourism_sos(
            owner=request.auth.owner,
            trip=trip,
            latitude=s.validated_data.get("latitude"),
            longitude=s.validated_data.get("longitude"),
            notes=s.validated_data.get("notes") or "",
        )
        return Response(assistance_case_to_dict(case), status=status.HTTP_201_CREATED)
