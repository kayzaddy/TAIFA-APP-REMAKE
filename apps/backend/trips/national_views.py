"""National Mobility API — command center, intercity, PT, enterprise, emergency, open platform."""
from __future__ import annotations

from decimal import Decimal, InvalidOperation

from django.shortcuts import get_object_or_404
from django.utils import timezone
from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework import serializers
from rest_framework.response import Response
from rest_framework.views import APIView

from payments.auth import IsDevice

from .adapters.government import government_adapter
from .national_models import (
    EnterpriseEmployee,
    EnterpriseOrganization,
    IntercityCorridor,
    IntercityDeparture,
    PartnerApiCredential,
    PublicTransitRoute,
    PublicTransitTimetable,
)
from .national_ops import (
    build_national_daily_metrics,
    national_analytics,
    national_command_center,
    national_map_layers,
    national_optimization_recommendations,
)
from .national_services import (
    authorize_enterprise_trip,
    book_intercity_departure,
    create_emergency_dispatch,
    create_logistics_shipment,
    create_partner_credential,
    issue_transit_ticket,
    validate_ticket,
)
from .permissions import IsMobilityOperator, has_permission
from .services import MobilityError, create_trip, dispatch_trip
from .models import TripKind


class IntercityCorridorSerializer(serializers.ModelSerializer):
    class Meta:
        model = IntercityCorridor
        fields = "__all__"
        read_only_fields = ["id", "created_at"]


class IntercityDepartureSerializer(serializers.ModelSerializer):
    class Meta:
        model = IntercityDeparture
        fields = "__all__"
        read_only_fields = ["id", "created_at", "trip"]


class PublicTransitRouteSerializer(serializers.ModelSerializer):
    class Meta:
        model = PublicTransitRoute
        fields = "__all__"
        read_only_fields = ["id", "created_at"]


class EnterpriseOrganizationSerializer(serializers.ModelSerializer):
    class Meta:
        model = EnterpriseOrganization
        fields = "__all__"
        read_only_fields = ["id", "created_at"]


@extend_schema(tags=["mobility-national"])
class NationalCommandCenterView(APIView):
    permission_classes = [IsDevice, IsMobilityOperator]

    def get(self, request):
        return Response(national_command_center())


@extend_schema(
    tags=["mobility-national"],
    parameters=[OpenApiParameter("region", str, required=False)],
)
class NationalMapView(APIView):
    permission_classes = [IsDevice, IsMobilityOperator]

    def get(self, request):
        region = request.query_params.get("region") or None
        return Response(national_map_layers(region=region))


@extend_schema(tags=["mobility-national"])
class NationalAnalyticsView(APIView):
    permission_classes = [IsDevice, IsMobilityOperator]

    def get(self, request):
        return Response(
            national_analytics(
                region=request.query_params.get("region", "").strip(),
                days=int(request.query_params.get("days", 30)),
            )
        )


@extend_schema(tags=["mobility-national"])
class NationalOptimizationView(APIView):
    permission_classes = [IsDevice, IsMobilityOperator]

    def get(self, request):
        return Response(national_optimization_recommendations())


@extend_schema(tags=["mobility-national"])
class NationalReportView(APIView):
    permission_classes = [IsDevice, IsMobilityOperator]

    def post(self, request):
        authority = str(request.data.get("authority", "LATRA")).upper()
        period_start = request.data.get("period_start")
        period_end = request.data.get("period_end")
        if not period_start or not period_end:
            return Response({"detail": "period_start and period_end required"}, status=400)
        analytics = national_analytics(days=90)
        adapter = government_adapter(authority)
        result = adapter.submit_transport_statistics(
            period_start=str(period_start),
            period_end=str(period_end),
            payload=analytics,
        )
        from .models import MobilityRegulatoryReport

        report = MobilityRegulatoryReport.objects.create(
            report_type="national_transport",
            authority=authority,
            period_start=period_start,
            period_end=period_end,
            payload={
                "adapter_reference": result.reference,
                "accepted": result.accepted,
                "analytics": analytics,
            },
        )
        return Response(
            {
                "id": str(report.id),
                "authority": authority,
                "reference": result.reference,
                "accepted": result.accepted,
            },
            status=201,
        )


@extend_schema(tags=["mobility-intercity"])
class IntercityCorridorView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = IntercityCorridor.objects.filter(active=True)
        return Response(IntercityCorridorSerializer(qs[:200], many=True).data)

    def post(self, request):
        if not has_permission(request, "mobility.operations"):
            return Response({"detail": "operations permission required"}, status=403)
        serializer = IntercityCorridorSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        row = serializer.save()
        return Response(IntercityCorridorSerializer(row).data, status=201)


@extend_schema(tags=["mobility-intercity"])
class IntercityDepartureView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = IntercityDeparture.objects.filter(status__in=["scheduled", "full"]).order_by("departs_at")
        corridor = request.query_params.get("corridor")
        if corridor:
            qs = qs.filter(corridor_id=corridor)
        return Response(IntercityDepartureSerializer(qs[:200], many=True).data)

    def post(self, request):
        serializer = IntercityDepartureSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        if data["seats_available"] > data["seats_total"]:
            return Response({"detail": "seats_available exceeds seats_total"}, status=400)
        row = serializer.save(operator_principal=request.auth.owner)
        return Response(IntercityDepartureSerializer(row).data, status=201)


@extend_schema(tags=["mobility-intercity"])
class IntercityBookView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, departure_id):
        try:
            booking = book_intercity_departure(
                departure_id=departure_id,
                owner=request.auth.owner,
                seats=int(request.data.get("seats", 1)),
            )
        except (MobilityError, IntercityDeparture.DoesNotExist) as exc:
            return Response({"detail": str(exc)}, status=409)
        return Response(
            {
                "id": str(booking.id),
                "ticket_code": booking.ticket_code,
                "fare_minor": booking.fare_minor,
                "currency": booking.currency,
                "status": booking.status,
                "payment_note": "Collect fare via Taifa Payments using ticket_code as reference.",
            },
            status=201,
        )


@extend_schema(tags=["mobility-public-transit"])
class PublicTransitRouteView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = PublicTransitRoute.objects.filter(active=True)
        region = request.query_params.get("region")
        if region:
            qs = qs.filter(region__iexact=region)
        return Response(PublicTransitRouteSerializer(qs[:200], many=True).data)

    def post(self, request):
        if not has_permission(request, "mobility.operations"):
            return Response({"detail": "operations permission required"}, status=403)
        serializer = PublicTransitRouteSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        row = serializer.save(operator_principal=request.data.get("operator_principal", request.auth.owner))
        return Response(PublicTransitRouteSerializer(row).data, status=201)


@extend_schema(tags=["mobility-public-transit"])
class TransitTicketIssueView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        try:
            ticket = issue_transit_ticket(
                owner=request.auth.owner,
                route_id=request.data["route_id"],
                ticket_type=request.data.get("ticket_type", "single"),
                fare_minor=request.data.get("fare_minor"),
                days_valid=int(request.data.get("days_valid", 1)),
            )
        except (KeyError, PublicTransitRoute.DoesNotExist, ValueError) as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(
            {
                "id": str(ticket.id),
                "media_code": ticket.media_code,
                "ticket_type": ticket.ticket_type,
                "fare_minor": ticket.fare_minor,
                "valid_to": ticket.valid_to.isoformat(),
                "payment_note": "Settle via Taifa Payments; store payment_ref on ticket after capture.",
            },
            status=201,
        )


@extend_schema(tags=["mobility-public-transit"])
class TransitTicketValidateView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        try:
            ticket = validate_ticket(media_code=str(request.data.get("media_code", "")))
        except Exception as exc:
            return Response({"detail": str(exc)}, status=409)
        return Response(
            {
                "media_code": ticket.media_code,
                "status": ticket.status,
                "ticket_type": ticket.ticket_type,
                "valid_to": ticket.valid_to.isoformat(),
            }
        )


@extend_schema(tags=["mobility-enterprise"])
class EnterpriseOrganizationView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = EnterpriseOrganization.objects.filter(active=True)
        if not has_permission(request, "mobility.operations"):
            qs = qs.filter(billing_account=request.auth.owner)
        return Response(EnterpriseOrganizationSerializer(qs[:100], many=True).data)

    def post(self, request):
        serializer = EnterpriseOrganizationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        row = serializer.save(
            billing_account=request.data.get("billing_account", request.auth.owner)
        )
        return Response(EnterpriseOrganizationSerializer(row).data, status=201)


@extend_schema(tags=["mobility-enterprise"])
class EnterpriseEmployeeView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, org_id):
        org = get_object_or_404(EnterpriseOrganization, pk=org_id)
        if org.billing_account != request.auth.owner and not has_permission(
            request, "mobility.operations"
        ):
            return Response({"detail": "enterprise access denied"}, status=403)
        employee, created = EnterpriseEmployee.objects.update_or_create(
            organization=org,
            principal=request.data.get("principal", request.auth.owner),
            defaults={
                "department": request.data.get("department", ""),
                "employee_code": request.data.get("employee_code", ""),
                "active": True,
            },
        )
        return Response(
            {
                "id": str(employee.id),
                "principal": employee.principal,
                "department": employee.department,
            },
            status=201 if created else 200,
        )


@extend_schema(tags=["mobility-enterprise"])
class EnterpriseTripView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        try:
            org = authorize_enterprise_trip(
                organization_code=str(request.data["organization_code"]),
                employee_principal=request.auth.owner,
                department=str(request.data.get("department", "")),
            )
            trip = create_trip(
                owner=request.auth.owner,
                actor=request.auth.owner,
                pickup_name=request.data["pickup_name"],
                pickup_lat=Decimal(str(request.data["pickup_lat"])),
                pickup_lng=Decimal(str(request.data["pickup_lng"])),
                dropoff_name=request.data["dropoff_name"],
                dropoff_lat=Decimal(str(request.data["dropoff_lat"])),
                dropoff_lng=Decimal(str(request.data["dropoff_lng"])),
                vehicle_mode=request.data.get("vehicle_mode", "taxi"),
                kind=TripKind.CORPORATE,
                dispatch_strategy="corporate",
                region=request.data.get("region", org.region),
                estimated_distance_meters=int(request.data.get("estimated_distance_meters", 5000)),
                estimated_duration_seconds=int(request.data.get("estimated_duration_seconds", 900)),
                payment_method="wallet",
                corporate_account=org.billing_account,
            )
            if not trip.scheduled_at:
                dispatch_trip(trip.id)
                trip.refresh_from_db()
        except (KeyError, MobilityError, InvalidOperation, ValueError) as exc:
            return Response({"detail": str(exc)}, status=400)
        from .serializers import TripSerializer

        return Response(TripSerializer(trip).data, status=201)


@extend_schema(tags=["mobility-emergency"])
class EmergencyDispatchView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        try:
            row = create_emergency_dispatch(
                requester=request.auth.owner,
                kind=str(request.data.get("kind", "ambulance")),
                region=str(request.data["region"]),
                district=str(request.data.get("district", "")),
                pickup_name=str(request.data["pickup_name"]),
                pickup_lat=Decimal(str(request.data["pickup_lat"])),
                pickup_lng=Decimal(str(request.data["pickup_lng"])),
                dropoff_name=str(request.data.get("dropoff_name", "")),
                dropoff_lat=Decimal(str(request.data["dropoff_lat"]))
                if request.data.get("dropoff_lat") is not None
                else None,
                dropoff_lng=Decimal(str(request.data["dropoff_lng"]))
                if request.data.get("dropoff_lng") is not None
                else None,
                severity=str(request.data.get("severity", "critical")),
            )
        except (KeyError, MobilityError, InvalidOperation, ValueError) as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(
            {
                "id": str(row.id),
                "status": row.status,
                "trip_id": str(row.trip_id) if row.trip_id else None,
                "kind": row.kind,
            },
            status=201,
        )


@extend_schema(tags=["mobility-logistics"])
class LogisticsShipmentView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        try:
            shipment = create_logistics_shipment(
                owner=request.auth.owner,
                category=str(request.data.get("category", "courier")),
                origin_name=str(request.data["origin_name"]),
                origin_lat=Decimal(str(request.data["origin_lat"])),
                origin_lng=Decimal(str(request.data["origin_lng"])),
                destination_name=str(request.data["destination_name"]),
                destination_lat=Decimal(str(request.data["destination_lat"])),
                destination_lng=Decimal(str(request.data["destination_lng"])),
                region=str(request.data.get("region", "")),
                vehicle_mode=str(request.data.get("vehicle_mode", "truck")),
                weight_kg_e2=int(request.data.get("weight_kg_e2", 0)),
                warehouse_code=str(request.data.get("warehouse_code", "")),
                recipient_name=str(request.data.get("recipient_name", "")),
                recipient_phone_masked=str(request.data.get("recipient_phone_masked", "")),
                verification_code=str(request.data.get("verification_code", "0000")),
            )
        except (KeyError, MobilityError, InvalidOperation, ValueError) as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(
            {
                "id": str(shipment.id),
                "status": shipment.status,
                "trip_id": str(shipment.trip_id) if shipment.trip_id else None,
                "delivery_id": str(shipment.delivery_id) if shipment.delivery_id else None,
            },
            status=201,
        )


@extend_schema(tags=["mobility-open-platform"])
class PartnerCredentialView(APIView):
    permission_classes = [IsDevice, IsMobilityOperator]

    def post(self, request):
        try:
            cred, raw_key = create_partner_credential(
                partner_code=str(request.data["partner_code"]),
                legal_name=str(request.data["legal_name"]),
                owner_principal=str(request.data.get("owner_principal", request.auth.owner)),
                scopes=request.data.get("scopes"),
            )
        except (KeyError, Exception) as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(
            {
                "id": str(cred.id),
                "partner_code": cred.partner_code,
                "api_key": raw_key,
                "api_key_prefix": cred.api_key_prefix,
                "scopes": cred.scopes,
                "note": "Store api_key once; only the hash is retained.",
            },
            status=201,
        )


@extend_schema(tags=["mobility-open-platform"])
class PartnerCatalogView(APIView):
    """Versioned open-platform catalog for municipalities and developers."""

    permission_classes = [IsDevice]

    def get(self, request):
        return Response(
            {
                "api_version": "v1",
                "platform": "taifa-national-mobility",
                "endpoints": [
                    {"path": "/api/v1/trips/national/command-center", "scope": "mobility.national.read"},
                    {"path": "/api/v1/trips/national/map", "scope": "mobility.national.read"},
                    {"path": "/api/v1/trips/national/analytics", "scope": "mobility.national.read"},
                    {"path": "/api/v1/trips/intercity/corridors", "scope": "mobility.read"},
                    {"path": "/api/v1/trips/public-transit/routes", "scope": "mobility.read"},
                    {"path": "/api/v1/trips/logistics/shipments", "scope": "mobility.trips.write"},
                    {"path": "/api/v1/trips/emergency/dispatch", "scope": "mobility.trips.write"},
                ],
                "shared_services": [
                    "taifa-identity",
                    "taifa-payments",
                    "taifa-mobility-registry",
                    "taifa-notifications",
                    "taifa-analytics",
                ],
                "partners_registered": PartnerApiCredential.objects.filter(active=True).count(),
            }
        )
