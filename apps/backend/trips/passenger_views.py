"""Passenger preference, recurring rides, accounts, and regional supervisor APIs."""
from __future__ import annotations

from datetime import datetime, timedelta

from django.shortcuts import get_object_or_404
from django.utils import timezone
from drf_spectacular.utils import extend_schema
from rest_framework.response import Response
from rest_framework.views import APIView

from payments.auth import IsDevice

from .models import (
    Delivery,
    Driver,
    DriverSchedule,
    Fleet,
    MobilityAccountLink,
    MobilityFavorite,
    MobilityZone,
    RecurringRidePlan,
    RegionalSupervisorAssignment,
    Station,
    Trip,
    TripKind,
    Vehicle,
    VehicleOperationalLog,
)
from .permissions import IsMobilityOperator, has_permission
from .serializers import (
    DeliverySerializer,
    DriverSerializer,
    VehicleOperationalLogSerializer,
    VehicleSerializer,
)
from .services import MobilityError, create_trip
from .city_ops import regional_kpis, rank_stations, city_map_snapshot
from rest_framework import serializers


class MobilityFavoriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = MobilityFavorite
        fields = ["id", "subject_type", "subject_id", "label", "created_at"]
        read_only_fields = ["id", "created_at"]


class RecurringRidePlanSerializer(serializers.ModelSerializer):
    class Meta:
        model = RecurringRidePlan
        fields = [
            "id",
            "label",
            "pickup_name",
            "pickup_lat",
            "pickup_lng",
            "dropoff_name",
            "dropoff_lat",
            "dropoff_lng",
            "vehicle_mode",
            "region",
            "estimated_distance_meters",
            "estimated_duration_seconds",
            "payment_method",
            "corporate_account",
            "weekdays",
            "local_time",
            "active",
            "last_materialized_on",
            "created_at",
        ]
        read_only_fields = ["id", "last_materialized_on", "created_at"]


class MobilityAccountLinkSerializer(serializers.ModelSerializer):
    class Meta:
        model = MobilityAccountLink
        fields = [
            "id",
            "account_code",
            "account_type",
            "member_principal",
            "role",
            "active",
            "metadata",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]


class MobilityZoneSerializer(serializers.ModelSerializer):
    class Meta:
        model = MobilityZone
        fields = [
            "id",
            "code",
            "name",
            "region",
            "district",
            "ward",
            "polygon",
            "active",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]


class DriverScheduleSerializer(serializers.ModelSerializer):
    class Meta:
        model = DriverSchedule
        fields = ["id", "driver", "station", "starts_at", "ends_at", "status", "created_at"]
        read_only_fields = ["id", "created_at"]


@extend_schema(tags=["mobility-passenger"])
class FavoriteListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        rows = MobilityFavorite.objects.filter(owner=request.auth.owner).order_by("-created_at")
        return Response(MobilityFavoriteSerializer(rows, many=True).data)

    def post(self, request):
        serializer = MobilityFavoriteSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        subject_type = serializer.validated_data["subject_type"]
        subject_id = str(serializer.validated_data["subject_id"])
        if subject_type == MobilityFavorite.SubjectType.DRIVER:
            if not Driver.objects.filter(pk=subject_id, registry_approval_id__isnull=False).exists():
                return Response({"detail": "driver not found or not verified"}, status=404)
        elif subject_type == MobilityFavorite.SubjectType.STATION:
            if not Station.objects.filter(
                pk=subject_id, active=True, registry_approval_id__isnull=False
            ).exists():
                return Response({"detail": "station not found or not approved"}, status=404)
        favorite, _ = MobilityFavorite.objects.update_or_create(
            owner=request.auth.owner,
            subject_type=subject_type,
            subject_id=subject_id,
            defaults={"label": serializer.validated_data.get("label", "")},
        )
        return Response(MobilityFavoriteSerializer(favorite).data, status=201)


@extend_schema(tags=["mobility-passenger"])
class FavoriteDeleteView(APIView):
    permission_classes = [IsDevice]

    def delete(self, request, favorite_id):
        deleted, _ = MobilityFavorite.objects.filter(
            pk=favorite_id, owner=request.auth.owner
        ).delete()
        if not deleted:
            return Response({"detail": "not found"}, status=404)
        return Response(status=204)


@extend_schema(tags=["mobility-passenger"])
class RecurringRidePlanView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        rows = RecurringRidePlan.objects.filter(owner=request.auth.owner).order_by("-created_at")
        return Response(RecurringRidePlanSerializer(rows, many=True).data)

    def post(self, request):
        serializer = RecurringRidePlanSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        weekdays = serializer.validated_data.get("weekdays") or []
        if not weekdays or any(day not in range(7) for day in weekdays):
            return Response({"detail": "weekdays must be integers 0-6"}, status=400)
        plan = serializer.save(owner=request.auth.owner)
        return Response(RecurringRidePlanSerializer(plan).data, status=201)


@extend_schema(tags=["mobility-passenger"])
class MobilityAccountView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        rows = MobilityAccountLink.objects.filter(
            member_principal=request.auth.owner, active=True
        )
        return Response(MobilityAccountLinkSerializer(rows, many=True).data)

    def post(self, request):
        serializer = MobilityAccountLinkSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        link, created = MobilityAccountLink.objects.update_or_create(
            account_code=serializer.validated_data["account_code"],
            member_principal=request.auth.owner,
            defaults={
                "account_type": serializer.validated_data["account_type"],
                "role": serializer.validated_data.get("role", "member"),
                "active": True,
                "metadata": serializer.validated_data.get("metadata") or {},
            },
        )
        return Response(
            MobilityAccountLinkSerializer(link).data,
            status=201 if created else 200,
        )


@extend_schema(tags=["mobility-passenger"])
class SharedRideCreateView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        from datetime import datetime
        from decimal import Decimal, InvalidOperation

        from .serializers import TripSerializer
        from .services import dispatch_trip

        seats = int(request.data.get("seats", 2))
        if seats < 2 or seats > 4:
            return Response({"detail": "shared rides require 2-4 seats"}, status=400)
        try:
            scheduled_raw = request.data.get("scheduled_at")
            scheduled_at = None
            if scheduled_raw:
                scheduled_at = datetime.fromisoformat(str(scheduled_raw).replace("Z", "+00:00"))
                if timezone.is_naive(scheduled_at):
                    scheduled_at = timezone.make_aware(scheduled_at)
            trip = create_trip(
                owner=request.auth.owner,
                actor=request.auth.owner,
                pickup_name=str(request.data["pickup_name"]),
                pickup_lat=Decimal(str(request.data["pickup_lat"])),
                pickup_lng=Decimal(str(request.data["pickup_lng"])),
                dropoff_name=str(request.data["dropoff_name"]),
                dropoff_lat=Decimal(str(request.data["dropoff_lat"])),
                dropoff_lng=Decimal(str(request.data["dropoff_lng"])),
                vehicle_mode=request.data.get("vehicle_mode", "bajaji"),
                kind=TripKind.PASSENGER,
                dispatch_strategy=request.data.get("dispatch_strategy", "station_first"),
                region=request.data.get("region", ""),
                estimated_distance_meters=int(request.data.get("estimated_distance_meters", 0)),
                estimated_duration_seconds=int(request.data.get("estimated_duration_seconds", 0)),
                payment_method=request.data.get("payment_method", "wallet"),
                corporate_account=request.data.get("corporate_account", ""),
                scheduled_at=scheduled_at,
            )
        except (KeyError, MobilityError, ValueError, TypeError, InvalidOperation) as exc:
            return Response({"detail": str(exc)}, status=400)
        metadata = dict(trip.metadata or {})
        metadata["shared_ride"] = True
        metadata["seats"] = seats
        trip.metadata = metadata
        trip.save(update_fields=["metadata", "updated_at"])
        if not trip.scheduled_at:
            try:
                dispatch_trip(trip.id)
                trip.refresh_from_db()
            except MobilityError:
                pass
        return Response(TripSerializer(trip).data, status=201)


@extend_schema(tags=["mobility-delivery"])
class DeliveryListView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = Delivery.objects.select_related("trip").filter(trip__owner=request.auth.owner)
        category = request.query_params.get("category")
        if category:
            qs = qs.filter(category=category)
        return Response(DeliverySerializer(qs.order_by("-trip__created_at")[:100], many=True).data)


@extend_schema(tags=["mobility-fleets"])
class FleetDriversView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, fleet_id):
        fleet = get_object_or_404(Fleet, pk=fleet_id)
        if fleet.owner_principal != request.auth.owner and not has_permission(
            request, "mobility.operations"
        ):
            return Response({"detail": "fleet access denied"}, status=403)
        drivers = fleet.drivers.all().order_by("full_name")
        return Response(DriverSerializer(drivers, many=True).data)


@extend_schema(tags=["mobility-fleets"])
class FleetVehiclesView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, fleet_id):
        fleet = get_object_or_404(Fleet, pk=fleet_id)
        if fleet.owner_principal != request.auth.owner and not has_permission(
            request, "mobility.operations"
        ):
            return Response({"detail": "fleet access denied"}, status=403)
        return Response(VehicleSerializer(fleet.vehicles.all(), many=True).data)


@extend_schema(tags=["mobility-fleets"])
class FleetScheduleView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, fleet_id):
        fleet = get_object_or_404(Fleet, pk=fleet_id)
        if fleet.owner_principal != request.auth.owner and not has_permission(
            request, "mobility.operations"
        ):
            return Response({"detail": "fleet access denied"}, status=403)
        rows = DriverSchedule.objects.filter(driver__fleet=fleet).order_by("starts_at")[:200]
        return Response(DriverScheduleSerializer(rows, many=True).data)

    def post(self, request, fleet_id):
        fleet = get_object_or_404(Fleet, pk=fleet_id, owner_principal=request.auth.owner)
        serializer = DriverScheduleSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        driver = serializer.validated_data["driver"]
        if driver.fleet_id != fleet.id:
            return Response({"detail": "driver not in fleet"}, status=400)
        schedule = serializer.save()
        return Response(DriverScheduleSerializer(schedule).data, status=201)


@extend_schema(tags=["mobility-fleets"])
class FleetFuelView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, fleet_id):
        fleet = get_object_or_404(Fleet, pk=fleet_id)
        if fleet.owner_principal != request.auth.owner and not has_permission(
            request, "mobility.operations"
        ):
            return Response({"detail": "fleet access denied"}, status=403)
        logs = VehicleOperationalLog.objects.filter(
            vehicle__fleet=fleet, kind="fuel"
        ).order_by("-occurred_at")[:200]
        return Response(VehicleOperationalLogSerializer(logs, many=True).data)

    def post(self, request, fleet_id):
        fleet = get_object_or_404(Fleet, pk=fleet_id, owner_principal=request.auth.owner)
        serializer = VehicleOperationalLogSerializer(data={**request.data, "kind": "fuel"})
        serializer.is_valid(raise_exception=True)
        vehicle = serializer.validated_data["vehicle"]
        if vehicle.fleet_id != fleet.id:
            return Response({"detail": "vehicle not in fleet"}, status=400)
        log = serializer.save(kind="fuel")
        return Response(VehicleOperationalLogSerializer(log).data, status=201)


@extend_schema(tags=["mobility-fleets"])
class FleetSettlementsView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, fleet_id):
        fleet = get_object_or_404(Fleet, pk=fleet_id)
        if fleet.owner_principal != request.auth.owner and not has_permission(
            request, "mobility.operations"
        ):
            return Response({"detail": "fleet access denied"}, status=403)
        trips = Trip.objects.filter(
            driver__fleet=fleet,
            payment_transaction__isnull=False,
        ).order_by("-completed_at")[:100]
        return Response(
            {
                "fleet_id": str(fleet.id),
                "settlements": [
                    {
                        "trip_id": str(t.id),
                        "fare_minor": t.fare_minor,
                        "currency": t.currency,
                        "payment_ref": t.payment_ref,
                        "payment_transaction_id": str(t.payment_transaction_id),
                        "completed_at": t.completed_at.isoformat() if t.completed_at else None,
                    }
                    for t in trips
                ],
                "note": "Settlement money truth remains in Taifa Payments.",
            }
        )


@extend_schema(tags=["mobility-regional"])
class RegionalSupervisorDashboardView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        assignments = list(
            RegionalSupervisorAssignment.objects.filter(
                principal=request.auth.owner, active=True
            ).select_related("zone")
        )
        if not assignments and not has_permission(request, "mobility.operations"):
            return Response({"detail": "no regional assignment"}, status=403)
        if not assignments and has_permission(request, "mobility.operations"):
            region = request.query_params.get("region", "Dar es Salaam")
            district = request.query_params.get("district", "")
            return Response(
                {
                    "scope": "operations_override",
                    "kpis": regional_kpis(region=region, district=district),
                    "stations": rank_stations(region=region, district=district, limit=25),
                    "map": city_map_snapshot(region=region, district=district),
                }
            )
        primary = assignments[0]
        district = primary.district if primary.scope in {"district", "zone"} else ""
        return Response(
            {
                "assignments": [
                    {
                        "id": str(a.id),
                        "scope": a.scope,
                        "region": a.region,
                        "district": a.district,
                        "zone": a.zone.code if a.zone_id else None,
                        "role_title": a.role_title,
                    }
                    for a in assignments
                ],
                "kpis": regional_kpis(region=primary.region, district=district),
                "stations": rank_stations(region=primary.region, district=district, limit=25),
                "map_summary": city_map_snapshot(
                    region=primary.region, district=district
                )["summary"],
            }
        )


@extend_schema(tags=["mobility-regional"])
class MobilityZoneView(APIView):
    permission_classes = [IsDevice, IsMobilityOperator]

    def get(self, request):
        qs = MobilityZone.objects.filter(active=True)
        region = request.query_params.get("region")
        if region:
            qs = qs.filter(region__iexact=region)
        return Response(MobilityZoneSerializer(qs[:200], many=True).data)

    def post(self, request):
        serializer = MobilityZoneSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        zone = serializer.save()
        return Response(MobilityZoneSerializer(zone).data, status=201)


def materialize_recurring_rides(*, day=None) -> dict:
    """Create scheduled trips for active recurring plans matching weekday."""
    day = day or timezone.localdate()
    weekday = day.weekday()
    created = 0
    skipped = 0
    for plan in RecurringRidePlan.objects.filter(active=True):
        if weekday not in (plan.weekdays or []):
            skipped += 1
            continue
        if plan.last_materialized_on == day:
            skipped += 1
            continue
        scheduled_at = timezone.make_aware(datetime.combine(day, plan.local_time))
        if scheduled_at < timezone.now() - timedelta(minutes=5):
            skipped += 1
            continue
        try:
            create_trip(
                owner=plan.owner,
                actor="celery:recurring",
                pickup_name=plan.pickup_name,
                pickup_lat=plan.pickup_lat,
                pickup_lng=plan.pickup_lng,
                dropoff_name=plan.dropoff_name,
                dropoff_lat=plan.dropoff_lat,
                dropoff_lng=plan.dropoff_lng,
                vehicle_mode=plan.vehicle_mode,
                region=plan.region,
                estimated_distance_meters=plan.estimated_distance_meters,
                estimated_duration_seconds=plan.estimated_duration_seconds,
                payment_method=plan.payment_method,
                corporate_account=plan.corporate_account,
                scheduled_at=scheduled_at,
            )
            plan.last_materialized_on = day
            plan.save(update_fields=["last_materialized_on", "updated_at"])
            created += 1
        except MobilityError:
            skipped += 1
    return {"created": created, "skipped": skipped, "day": str(day)}
