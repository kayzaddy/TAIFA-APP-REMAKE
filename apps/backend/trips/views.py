from django.contrib.auth.hashers import check_password, make_password
from django.db.models import Q, Sum
from django.shortcuts import get_object_or_404
from django.utils import timezone
from drf_spectacular.utils import OpenApiParameter, extend_schema, extend_schema_view
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from payments import audit
from payments.auth import IsDevice

from .models import (
    DispatchOffer,
    Delivery,
    Driver,
    DriverAvailability,
    DriverLocation,
    DriverStatus,
    DriverVerification,
    Fleet,
    MobilityNotification,
    MobilityRegulatoryReport,
    PricingRule,
    Rating,
    SafetyIncident,
    SavedLocation,
    Station,
    StationQueueEntry,
    Trip,
    TripKind,
    TripStatus,
    Vehicle,
    VehicleOperationalLog,
    VerificationStatus,
)
from .permissions import CanManageStations, CanViewRegulatory, IsMobilityOperator
from .realtime import broadcast_trip
from .intelligence import (
    driver_positioning_recommendations,
    forecast_station_demand,
    maintenance_prediction,
)
from .serializers import (
    AcceptedLocationBatchSerializer,
    DispatchOfferSerializer,
    DeliveryCreateSerializer,
    DeliverySerializer,
    DriverLocationSerializer,
    DriverSerializer,
    DriverEarningsSerializer,
    FleetSerializer,
    FleetDashboardSerializer,
    MobilityIntelligenceSerializer,
    MobilityNotificationSerializer,
    OperationsDashboardSerializer,
    PricingRuleSerializer,
    QueueEntrySerializer,
    QueueReorderSerializer,
    RatingSerializer,
    RegulatoryReportRequestSerializer,
    RegulatoryReportResponseSerializer,
    SafetyIncidentSerializer,
    SavedLocationSerializer,
    StationCreateSerializer,
    StationSerializer,
    StationDashboardSerializer,
    TripCreateSerializer,
    TripPatchSerializer,
    TripSerializer,
    VehicleSerializer,
    VehicleOperationalLogSerializer,
    VerificationDecisionSerializer,
)
from .services import (
    MobilityError,
    accept_offer,
    collect_trip_payment,
    create_trip,
    dispatch_trip,
    join_station_queue,
    leave_station_queue,
    nearest_station,
    reject_offer,
    reorder_station_queue,
    transition_trip,
)


@extend_schema_view(
    get=extend_schema(tags=["trips"], responses=TripSerializer(many=True), operation_id="trips_list"),
    post=extend_schema(tags=["trips"], request=TripCreateSerializer, responses={201: TripSerializer}, operation_id="trips_create"),
)
class TripListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = Trip.objects.filter(owner=request.auth.owner)[:50]
        return Response(TripSerializer(qs, many=True).data)

    def post(self, request):
        s = TripCreateSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        d = dict(s.validated_data)
        hybrid_sms_demo = bool(d.pop("hybrid_sms_demo", False))
        passenger_msisdn = str(d.pop("passenger_msisdn", "") or "")
        try:
            trip = create_trip(owner=request.auth.owner, actor=request.auth.owner, **d)
        except MobilityError as exc:
            return Response({"detail": str(exc)}, status=400)
        meta = dict(trip.metadata or {})
        if hybrid_sms_demo:
            meta["hybrid_sms_demo"] = True
        if passenger_msisdn:
            meta["passenger_msisdn"] = passenger_msisdn
        if meta != (trip.metadata or {}):
            trip.metadata = meta
            trip.save(update_fields=["metadata", "updated_at"])
        # Persist the request even if no station/driver is ready yet — matching
        # continues asynchronously; failing the create here left riders with 500/400.
        if not trip.scheduled_at:
            try:
                from django.conf import settings

                if settings.DEBUG:
                    # Free demo drivers left in "offered" after abandoned local tests.
                    Driver.objects.filter(
                        owner_principal__startswith="demo-driver-",
                        availability=DriverAvailability.OFFERED,
                    ).update(availability=DriverAvailability.AVAILABLE)
                offers = dispatch_trip(trip.id)
                # Local/dev: auto-accept unless feature-phone SMS demo mode is on.
                if settings.DEBUG and offers and not hybrid_sms_demo:
                    try:
                        trip = accept_offer(offers[0].id, driver=offers[0].driver)
                    except MobilityError:
                        trip.refresh_from_db()
                else:
                    trip.refresh_from_db()
            except MobilityError:
                pass
        return Response(TripSerializer(trip).data, status=status.HTTP_201_CREATED)


@extend_schema_view(
    get=extend_schema(tags=["trips"], responses=TripSerializer, operation_id="trips_retrieve"),
    patch=extend_schema(tags=["trips"], request=TripPatchSerializer, responses=TripSerializer, operation_id="trips_partial_update"),
)
class TripDetailView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, trip_id):
        try:
            trip = Trip.objects.get(pk=trip_id, owner=request.auth.owner)
        except Trip.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        return Response(TripSerializer(trip).data)

    def patch(self, request, trip_id):
        try:
            trip = Trip.objects.get(pk=trip_id, owner=request.auth.owner)
        except Trip.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        s = TripPatchSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        target = s.validated_data["status"]
        # Customers may only cancel. Drivers may progress their assigned trip.
        is_assigned_driver = bool(
            trip.driver_id and trip.driver.owner_principal == request.auth.owner
        )
        if target != TripStatus.CANCELLED and not is_assigned_driver:
            return Response({"detail": "Only the assigned driver may progress this trip."}, status=403)
        try:
            trip = transition_trip(
                trip.id,
                to_status=target,
                actor=request.auth.owner,
                metadata=s.validated_data.get("metadata", {}),
            )
        except MobilityError as exc:
            return Response({"detail": str(exc)}, status=409)
        return Response(TripSerializer(trip).data)


@extend_schema_view(
    get=extend_schema(tags=["mobility-stations"], responses=StationSerializer(many=True)),
    post=extend_schema(tags=["mobility-stations"], request=StationCreateSerializer, responses=StationSerializer),
)
class StationListCreateView(APIView):
    def get_permissions(self):
        if self.request.method == "POST":
            return [IsDevice(), CanManageStations()]
        return [IsDevice()]

    def get(self, request):
        qs = Station.objects.filter(active=True)
        region = request.query_params.get("region")
        district = request.query_params.get("district")
        if request.query_params.get("managed") in {"1", "true", "yes"}:
            qs = qs.filter(manager_principal=request.auth.owner)
        if region:
            qs = qs.filter(region=region)
        if district:
            qs = qs.filter(district=district)
        return Response(StationSerializer(qs[:200], many=True).data)

    def post(self, request):
        serializer = StationCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        station = serializer.save()
        return Response(StationSerializer(station).data, status=201)


@extend_schema(
    tags=["mobility-stations"],
    parameters=[
        OpenApiParameter("lat", float, required=True),
        OpenApiParameter("lng", float, required=True),
        OpenApiParameter("region", str, required=False),
    ],
    responses=StationSerializer,
)
class NearbyStationView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        try:
            station = nearest_station(
                latitude=float(request.query_params["lat"]),
                longitude=float(request.query_params["lng"]),
                region=request.query_params.get("region", ""),
            )
        except (KeyError, ValueError):
            return Response({"detail": "lat and lng are required"}, status=400)
        if station is None:
            return Response({"detail": "No station within service radius"}, status=404)
        return Response(StationSerializer(station).data)


@extend_schema_view(
    get=extend_schema(tags=["mobility-fleets"], responses=FleetSerializer(many=True)),
    post=extend_schema(tags=["mobility-fleets"], request=FleetSerializer, responses=FleetSerializer),
)
class FleetListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = Fleet.objects.filter(owner_principal=request.auth.owner)
        return Response(FleetSerializer(qs, many=True).data)

    def post(self, request):
        serializer = FleetSerializer(data={**request.data, "owner_principal": request.auth.owner})
        serializer.is_valid(raise_exception=True)
        fleet = serializer.save(owner_principal=request.auth.owner)
        return Response(FleetSerializer(fleet).data, status=201)


@extend_schema_view(
    get=extend_schema(tags=["mobility-drivers"], responses=DriverSerializer),
    post=extend_schema(tags=["mobility-drivers"], request=DriverSerializer, responses=DriverSerializer),
)
class DriverProfileView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        driver = get_object_or_404(Driver, owner_principal=request.auth.owner)
        return Response(DriverSerializer(driver).data)

    def post(self, request):
        driver, _ = Driver.objects.get_or_create(
            owner_principal=request.auth.owner,
            defaults={
                "full_name": request.data.get("full_name", ""),
                "phone_masked": request.data.get("phone_masked", ""),
                "license_number": request.data.get("license_number", ""),
                "station_id": request.data.get("station"),
                "fleet_id": request.data.get("fleet"),
            },
        )
        return Response(DriverSerializer(driver).data, status=201)


@extend_schema(tags=["mobility-drivers"], request=None, responses=DriverSerializer)
class DriverAvailabilityView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        driver = get_object_or_404(Driver, owner_principal=request.auth.owner)
        target = request.data.get("availability")
        if target not in {
            DriverAvailability.AVAILABLE,
            DriverAvailability.OFFLINE,
            DriverAvailability.BREAK,
            DriverAvailability.BUSY,
            DriverAvailability.EMERGENCY,
        }:
            return Response({"detail": "invalid availability"}, status=400)
        if target == DriverAvailability.AVAILABLE:
            if (
                driver.status != DriverStatus.ACTIVE
                or driver.identity_status != VerificationStatus.VERIFIED
                or driver.license_status != VerificationStatus.VERIFIED
                or not driver.registry_approval_id
            ):
                return Response({"detail": "driver registry approval is inactive"}, status=409)
            if not driver.station_id or not Station.objects.filter(
                pk=driver.station_id,
                active=True,
                verification_status=VerificationStatus.VERIFIED,
                registry_approval_id__isnull=False,
            ).exists():
                return Response({"detail": "approved station assignment required"}, status=409)
            if driver.fleet_id and not Fleet.objects.filter(
                pk=driver.fleet_id,
                status=VerificationStatus.VERIFIED,
                registry_approval_id__isnull=False,
            ).exists():
                return Response({"detail": "fleet registry approval is inactive"}, status=409)
            if not driver.vehicles.filter(
                status="active",
                insurance_status=VerificationStatus.VERIFIED,
                road_license_status=VerificationStatus.VERIFIED,
                inspection_status=VerificationStatus.VERIFIED,
                registry_approval_id__isnull=False,
            ).exists():
                return Response({"detail": "no compliant active vehicle"}, status=409)
        driver.availability = target
        driver.save(update_fields=["availability", "updated_at"])
        return Response(DriverSerializer(driver).data)


@extend_schema(
    tags=["mobility-verification"],
    request=VerificationDecisionSerializer,
    responses=VerificationDecisionSerializer,
)
class VerificationDecisionView(APIView):
    permission_classes = [IsDevice, IsMobilityOperator]

    def post(self, request):
        serializer = VerificationDecisionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        resource_type = data["resource_type"]
        status_value = data["status"]
        actor = request.auth.owner
        if resource_type.startswith("driver_"):
            driver = get_object_or_404(Driver, pk=data["resource_id"])
            field = "identity_status" if resource_type == "driver_identity" else "license_status"
            before = getattr(driver, field)
            setattr(driver, field, status_value)
            if resource_type == "driver_license" and data.get("expires_at"):
                driver.license_expires_at = data["expires_at"].date()
            driver.save()
            driver.refresh_from_db()
            if (
                driver.identity_status == VerificationStatus.VERIFIED
                and driver.license_status == VerificationStatus.VERIFIED
                and driver.registry_approval_id
            ):
                Driver.objects.filter(pk=driver.pk).update(status=DriverStatus.ACTIVE)
            DriverVerification.objects.create(
                driver=driver,
                kind=resource_type,
                status=status_value,
                document_hash=data.get("evidence_hash", ""),
                reviewed_by=actor,
                reason=data.get("reason", ""),
                expires_at=data.get("expires_at"),
            )
            resource = driver
        else:
            vehicle = get_object_or_404(Vehicle, pk=data["resource_id"])
            field = {
                "vehicle_insurance": "insurance_status",
                "vehicle_road_license": "road_license_status",
                "vehicle_inspection": "inspection_status",
            }[resource_type]
            before = getattr(vehicle, field)
            setattr(vehicle, field, status_value)
            expires_field = {
                "vehicle_insurance": "insurance_expires_at",
                "vehicle_road_license": "road_license_expires_at",
                "vehicle_inspection": "inspection_expires_at",
            }[resource_type]
            if data.get("expires_at"):
                setattr(vehicle, expires_field, data["expires_at"].date())
            vehicle.save()
            vehicle.refresh_from_db()
            if all(
                getattr(vehicle, name) == VerificationStatus.VERIFIED
                for name in (
                    "insurance_status",
                    "road_license_status",
                    "inspection_status",
                )
            ) and vehicle.registry_approval_id:
                Vehicle.objects.filter(pk=vehicle.pk).update(status="active")
            resource = vehicle
        audit.record(
            actor=actor,
            action="mobility.verification.decide",
            resource_type=resource_type,
            resource_id=str(resource.pk),
            before={"status": before},
            after={"status": status_value, "reason": data.get("reason", "")},
        )
        return Response(serializer.data)


@extend_schema(tags=["mobility-drivers"], request=VehicleSerializer, responses=VehicleSerializer)
class VehicleListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = Vehicle.objects.filter(
            Q(owner_principal=request.auth.owner) | Q(assigned_driver__owner_principal=request.auth.owner)
        ).distinct()
        return Response(VehicleSerializer(qs, many=True).data)

    def post(self, request):
        serializer = VehicleSerializer(data={**request.data, "owner_principal": request.auth.owner})
        serializer.is_valid(raise_exception=True)
        assigned_driver = serializer.validated_data.get("assigned_driver")
        fleet = serializer.validated_data.get("fleet")
        if assigned_driver and assigned_driver.owner_principal != request.auth.owner:
            if not fleet or fleet.owner_principal != request.auth.owner or assigned_driver.fleet_id != fleet.id:
                return Response({"detail": "driver assignment is not owned by this fleet"}, status=403)
        if fleet and fleet.owner_principal != request.auth.owner:
            return Response({"detail": "fleet access denied"}, status=403)
        vehicle = serializer.save(owner_principal=request.auth.owner)
        return Response(VehicleSerializer(vehicle).data, status=201)


@extend_schema_view(
    get=extend_schema(tags=["mobility-fleets"], responses=VehicleOperationalLogSerializer(many=True)),
    post=extend_schema(tags=["mobility-fleets"], request=VehicleOperationalLogSerializer, responses=VehicleOperationalLogSerializer),
)
class VehicleOperationalLogView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, vehicle_id):
        vehicle = get_object_or_404(
            Vehicle.objects.filter(
                Q(owner_principal=request.auth.owner)
                | Q(assigned_driver__owner_principal=request.auth.owner)
            ),
            pk=vehicle_id,
        )
        return Response(
            VehicleOperationalLogSerializer(
                vehicle.operational_logs.order_by("-occurred_at")[:100],
                many=True,
            ).data
        )

    def post(self, request, vehicle_id):
        vehicle = get_object_or_404(
            Vehicle.objects.filter(
                Q(owner_principal=request.auth.owner)
                | Q(assigned_driver__owner_principal=request.auth.owner)
            ),
            pk=vehicle_id,
        )
        serializer = VehicleOperationalLogSerializer(
            data={**request.data, "vehicle": str(vehicle.id)}
        )
        serializer.is_valid(raise_exception=True)
        driver = Driver.objects.filter(owner_principal=request.auth.owner).first()
        row = serializer.save(vehicle=vehicle, driver=driver)
        if row.odometer_km > vehicle.odometer_km:
            vehicle.odometer_km = row.odometer_km
            vehicle.save(update_fields=["odometer_km", "updated_at"])
        return Response(VehicleOperationalLogSerializer(row).data, status=201)


@extend_schema(
    tags=["mobility-drivers"],
    request=DriverLocationSerializer(many=True),
    responses=AcceptedLocationBatchSerializer,
)
class DriverLocationBatchView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        driver = get_object_or_404(Driver, owner_principal=request.auth.owner)
        payload = request.data if isinstance(request.data, list) else [request.data]
        if len(payload) > 100:
            return Response({"detail": "maximum 100 points per batch"}, status=400)
        serializer = DriverLocationSerializer(data=payload, many=True)
        serializer.is_valid(raise_exception=True)
        last = driver.locations.order_by("-recorded_at").first()
        created = []
        latest_at = last.recorded_at if last else None
        now = timezone.now()
        for row in sorted(serializer.validated_data, key=lambda item: item["recorded_at"]):
            trip = row.get("trip")
            if trip and trip.driver_id != driver.id:
                return Response({"detail": "location trip is not assigned to driver"}, status=403)
            if row["recorded_at"] > now + timezone.timedelta(minutes=5):
                return Response({"detail": "location timestamp is in the future"}, status=400)
            if latest_at and row["recorded_at"] <= latest_at:
                continue  # idempotent offline replay
            point = DriverLocation.objects.create(driver=driver, **row)
            created.append(point)
            latest_at = point.recorded_at
        if created:
            latest = created[-1]
            if latest.trip_id:
                broadcast_trip(
                    latest.trip_id,
                    "mobility.driver.location",
                    {
                        "latitude": str(latest.latitude),
                        "longitude": str(latest.longitude),
                        "recorded_at": latest.recorded_at.isoformat(),
                    },
                )
        return Response({"accepted": len(created)}, status=202)


@extend_schema(tags=["mobility-dispatch"], responses=DispatchOfferSerializer(many=True))
class DriverOfferListView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        driver = get_object_or_404(Driver, owner_principal=request.auth.owner)
        offers = DispatchOffer.objects.filter(
            driver=driver,
            status="pending",
            expires_at__gt=timezone.now(),
        ).select_related("trip", "driver")
        return Response(DispatchOfferSerializer(offers, many=True).data)


@extend_schema(tags=["mobility-dispatch"], request=None, responses=TripSerializer)
class DriverOfferAcceptView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, offer_id):
        driver = get_object_or_404(Driver, owner_principal=request.auth.owner)
        try:
            trip = accept_offer(offer_id, driver=driver)
        except MobilityError as exc:
            return Response({"detail": str(exc)}, status=409)
        return Response(TripSerializer(trip).data)


@extend_schema(tags=["mobility-dispatch"], request=None, responses=DispatchOfferSerializer)
class DriverOfferRejectView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, offer_id):
        driver = get_object_or_404(Driver, owner_principal=request.auth.owner)
        try:
            offer = reject_offer(
                offer_id,
                driver=driver,
                reason=str(request.data.get("reason", "")),
            )
        except MobilityError as exc:
            return Response({"detail": str(exc)}, status=409)
        return Response(DispatchOfferSerializer(offer).data)


@extend_schema_view(
    get=extend_schema(tags=["mobility-stations"], responses=QueueEntrySerializer(many=True)),
    post=extend_schema(tags=["mobility-stations"], request=None, responses=QueueEntrySerializer),
)
class StationQueueView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, station_id):
        station = get_object_or_404(Station, pk=station_id)
        actor = request.auth.owner
        is_manager = station.manager_principal == actor
        is_assigned_driver = Driver.objects.filter(
            owner_principal=actor, station_id=station.id
        ).exists()
        if not is_manager and not is_assigned_driver:
            return Response({"detail": "station queue access denied"}, status=403)
        entries = (
            StationQueueEntry.objects.filter(station=station, active=True)
            .select_related("driver")
            .order_by("-priority", "position", "joined_at")
        )
        return Response(QueueEntrySerializer(entries, many=True).data)

    def post(self, request, station_id):
        station = get_object_or_404(Station, pk=station_id)
        driver = get_object_or_404(Driver, owner_principal=request.auth.owner)
        try:
            entry = join_station_queue(station=station, driver=driver)
        except MobilityError as exc:
            return Response({"detail": str(exc)}, status=409)
        return Response(QueueEntrySerializer(entry).data, status=201)


@extend_schema(tags=["mobility-stations"], request=None, responses=None)
class StationQueueLeaveView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, station_id):
        station = get_object_or_404(Station, pk=station_id)
        driver = get_object_or_404(Driver, owner_principal=request.auth.owner)
        if driver.station_id != station.id:
            return Response({"detail": "driver is not assigned to this station"}, status=403)
        leave_station_queue(driver=driver)
        return Response({"ok": True})


@extend_schema(
    tags=["mobility-stations"],
    request=QueueReorderSerializer,
    responses=QueueEntrySerializer(many=True),
)
class StationQueueReorderView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, station_id):
        station = get_object_or_404(Station, pk=station_id)
        serializer = QueueReorderSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            entries = reorder_station_queue(
                station=station,
                ordered_driver_ids=serializer.validated_data["ordered_driver_ids"],
                actor=request.auth.owner,
            )
        except MobilityError as exc:
            return Response({"detail": str(exc)}, status=409)
        return Response({"queue": QueueEntrySerializer(entries, many=True).data})


@extend_schema(tags=["mobility-payments"], request=None, responses=TripSerializer)
class TripPaymentView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, trip_id):
        trip = get_object_or_404(Trip, pk=trip_id, owner=request.auth.owner)
        key = request.headers.get("Idempotency-Key", "").strip()
        if not key:
            return Response({"detail": "Idempotency-Key required"}, status=400)
        try:
            trip = collect_trip_payment(trip.id, actor=request.auth.owner, idempotency_key=key)
        except MobilityError as exc:
            return Response({"detail": str(exc)}, status=409)
        return Response(TripSerializer(trip).data)


@extend_schema(tags=["mobility-safety"], request=SafetyIncidentSerializer, responses=SafetyIncidentSerializer)
class SafetyIncidentView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        serializer = SafetyIncidentSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        trip = serializer.validated_data.get("trip")
        if trip and request.auth.owner not in {
            trip.owner,
            getattr(trip.driver, "owner_principal", ""),
        }:
            return Response({"detail": "trip access denied"}, status=403)
        incident = serializer.save(reporter_principal=request.auth.owner)
        return Response(SafetyIncidentSerializer(incident).data, status=201)


@extend_schema(tags=["mobility-delivery"], request=DeliveryCreateSerializer, responses=DeliverySerializer)
class DeliveryCreateView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        serializer = DeliveryCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = dict(serializer.validated_data)
        trip = data.pop("trip")
        verification_code = data.pop("recipient_verification_code")
        if trip.owner != request.auth.owner or trip.kind != TripKind.DELIVERY:
            return Response({"detail": "delivery trip access denied"}, status=403)
        delivery = Delivery.objects.create(
            trip=trip,
            verification_hash=make_password(verification_code),
            **data,
        )
        return Response(DeliverySerializer(delivery).data, status=201)


@extend_schema(tags=["mobility-delivery"], request=None, responses=DeliverySerializer)
class DeliveryProofView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, delivery_id):
        delivery = get_object_or_404(
            Delivery.objects.select_related("trip__driver"),
            pk=delivery_id,
        )
        if (
            not delivery.trip.driver_id
            or delivery.trip.driver.owner_principal != request.auth.owner
        ):
            return Response({"detail": "assigned driver required"}, status=403)
        presented = str(request.data.get("recipient_verification_code", ""))
        if not presented or not check_password(presented, delivery.verification_hash):
            return Response({"detail": "recipient verification failed"}, status=403)
        delivery.proof_status = "verified"
        delivery.proof_metadata = {
            "method": "recipient_code",
            "location": request.data.get("location", {}),
        }
        delivery.delivered_at = timezone.now()
        delivery.save(update_fields=["proof_status", "proof_metadata", "delivered_at"])
        return Response(DeliverySerializer(delivery).data)


@extend_schema(tags=["mobility-ratings"], request=RatingSerializer, responses=RatingSerializer)
class RatingCreateView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        serializer = RatingSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        trip = serializer.validated_data["trip"]
        if trip.owner != request.auth.owner and getattr(trip.driver, "owner_principal", "") != request.auth.owner:
            return Response({"detail": "trip access denied"}, status=403)
        if trip.status not in {TripStatus.PAYMENT_CONFIRMED, TripStatus.SETTLED}:
            return Response({"detail": "trip is not payment-complete"}, status=409)
        rating = serializer.save(rater_principal=request.auth.owner)
        return Response(RatingSerializer(rating).data, status=201)


@extend_schema_view(
    get=extend_schema(tags=["mobility-profile"], responses=SavedLocationSerializer(many=True)),
    post=extend_schema(tags=["mobility-profile"], request=SavedLocationSerializer, responses=SavedLocationSerializer),
)
class SavedLocationView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        return Response(
            SavedLocationSerializer(
                SavedLocation.objects.filter(owner=request.auth.owner),
                many=True,
            ).data
        )

    def post(self, request):
        serializer = SavedLocationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        location = serializer.save(owner=request.auth.owner)
        return Response(SavedLocationSerializer(location).data, status=201)


@extend_schema(tags=["mobility-pricing"], request=PricingRuleSerializer, responses=PricingRuleSerializer)
class PricingRuleView(APIView):
    permission_classes = [IsDevice, IsMobilityOperator]

    def get(self, request):
        return Response(PricingRuleSerializer(PricingRule.objects.all(), many=True).data)

    def post(self, request):
        serializer = PricingRuleSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        rule = serializer.save()
        return Response(PricingRuleSerializer(rule).data, status=201)


@extend_schema(
    tags=["mobility-operations"],
    responses=OperationsDashboardSerializer,
)
class OperationsDashboardView(APIView):
    permission_classes = [IsDevice, IsMobilityOperator]

    def get(self, request):
        today = timezone.localdate()
        region = request.query_params.get("region", "").strip()
        district = request.query_params.get("district", "").strip()
        trips_scope = Trip.objects.all()
        drivers_scope = Driver.objects.all()
        stations_scope = Station.objects.filter(active=True)
        queue_scope = StationQueueEntry.objects.filter(active=True)
        if region:
            stations_scope = stations_scope.filter(region__iexact=region)
            trips_scope = trips_scope.filter(station__region__iexact=region)
            drivers_scope = drivers_scope.filter(station__region__iexact=region)
            queue_scope = queue_scope.filter(station__region__iexact=region)
        if district:
            stations_scope = stations_scope.filter(district__iexact=district)
            trips_scope = trips_scope.filter(station__district__iexact=district)
            drivers_scope = drivers_scope.filter(station__district__iexact=district)
            queue_scope = queue_scope.filter(station__district__iexact=district)
        trips_today = trips_scope.filter(created_at__date=today)
        requested = trips_today.count()
        completed = trips_scope.filter(completed_at__date=today).count()
        accepted = DispatchOffer.objects.filter(
            status="accepted",
            responded_at__date=today,
            trip__in=trips_today,
        ).count()
        offered = DispatchOffer.objects.filter(
            created_at__date=today,
            trip__in=trips_today,
        ).count()
        open_sos = SafetyIncident.objects.filter(status="open")
        if region:
            open_sos = open_sos.filter(trip__station__region__iexact=region)
        open_sos_count = open_sos.count()
        queue_total = queue_scope.count()
        acceptance_rate = int((accepted * 10_000) / offered) if offered else 0
        completion_rate = int((completed * 10_000) / requested) if requested else 0
        if open_sos_count > 0:
            health = "critical"
        elif acceptance_rate < 5_000 and offered > 10:
            health = "degraded"
        else:
            health = "healthy"
        return Response(
            {
                "region": region or "national",
                "district": district or "",
                "live_trips": trips_scope.exclude(
                    status__in=[
                        TripStatus.COMPLETED,
                        TripStatus.CANCELLED,
                        TripStatus.PAYMENT_CONFIRMED,
                        TripStatus.SETTLED,
                    ]
                ).count(),
                "available_drivers": drivers_scope.filter(
                    availability=DriverAvailability.AVAILABLE
                ).count(),
                "active_stations": stations_scope.count(),
                "open_sos": open_sos_count,
                "trips_today": requested,
                "completed_today": completed,
                "fare_today_minor": trips_scope.filter(
                    completed_at__date=today
                ).aggregate(total=Sum("fare_minor"))["total"]
                or 0,
                "acceptance_rate_e4": acceptance_rate,
                "completion_rate_e4": completion_rate,
                "queue_length_total": queue_total,
                "ride_requests_today": requested,
                "system_health": health,
            }
        )


@extend_schema(tags=["mobility-drivers"], responses=DriverEarningsSerializer)
class DriverEarningsView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        driver = get_object_or_404(Driver, owner_principal=request.auth.owner)
        now = timezone.now()
        windows = {
            "daily": now - timezone.timedelta(days=1),
            "weekly": now - timezone.timedelta(days=7),
            "monthly": now - timezone.timedelta(days=30),
        }
        payload = {}
        for label, since in windows.items():
            qs = Trip.objects.filter(
                driver=driver,
                payment_transaction__isnull=False,
                completed_at__gte=since,
            )
            payload[label] = {
                # Operational gross, not a wallet balance. Wallet remains Taifa Payments.
                "gross_fare_minor": qs.aggregate(total=Sum("fare_minor"))["total"] or 0,
                "trips": qs.count(),
                "currency": "TZS",
            }
        return Response(payload)


@extend_schema(tags=["mobility-fleets"], responses=FleetDashboardSerializer)
class FleetDashboardView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, fleet_id):
        fleet = get_object_or_404(Fleet, pk=fleet_id, owner_principal=request.auth.owner)
        trips = Trip.objects.filter(driver__fleet=fleet)
        return Response(
            {
                "fleet_id": str(fleet.id),
                "drivers": fleet.drivers.count(),
                "vehicles": fleet.vehicles.count(),
                "active_trips": trips.exclude(
                    status__in=[
                        TripStatus.COMPLETED,
                        TripStatus.CANCELLED,
                        TripStatus.PAYMENT_CONFIRMED,
                        TripStatus.SETTLED,
                    ]
                ).count(),
                "completed_trips": trips.filter(
                    status__in=[TripStatus.COMPLETED, TripStatus.PAYMENT_CONFIRMED, TripStatus.SETTLED]
                ).count(),
                "gross_fare_minor": trips.filter(
                    payment_transaction__isnull=False
                ).aggregate(total=Sum("fare_minor"))["total"]
                or 0,
            }
        )


@extend_schema(tags=["mobility-stations"], responses=StationDashboardSerializer)
class StationDashboardView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, station_id):
        station = get_object_or_404(
            Station,
            pk=station_id,
            manager_principal=request.auth.owner,
        )
        today = timezone.localdate()
        trips = station.trips.all()
        drivers = station.drivers.all()
        queue_length = StationQueueEntry.objects.filter(station=station, active=True).count()
        online = drivers.filter(
            availability__in=[
                DriverAvailability.AVAILABLE,
                DriverAvailability.OFFERED,
                DriverAvailability.ON_TRIP,
                DriverAvailability.BUSY,
            ]
        ).count()
        offline = drivers.filter(availability=DriverAvailability.OFFLINE).count()
        on_trip = drivers.filter(availability=DriverAvailability.ON_TRIP).count()
        available = drivers.filter(availability=DriverAvailability.AVAILABLE).count()
        completed_today = trips.filter(completed_at__date=today).count()
        cancelled_today = trips.filter(cancelled_at__date=today).count()
        requested_today = trips.filter(created_at__date=today).count()
        waiting = list(
            StationQueueEntry.objects.filter(station=station, active=True).values_list(
                "joined_at", flat=True
            )
        )
        now = timezone.now()
        avg_wait = 0
        if waiting:
            avg_wait = int(
                sum((now - joined).total_seconds() for joined in waiting) / len(waiting)
            )
        open_alerts = SafetyIncident.objects.filter(
            status="open",
            trip__station=station,
        ).count()
        completion_rate = (
            int((completed_today * 10_000) / requested_today) if requested_today else 0
        )
        utilization = int((queue_length * 10_000) / station.capacity) if station.capacity else 0
        if open_alerts > 0 or utilization >= 9_500:
            health = "critical"
        elif utilization >= 8_000 or cancelled_today > completed_today:
            health = "degraded"
        else:
            health = "healthy"
        return Response(
            {
                "station": StationSerializer(station).data,
                "capacity": station.capacity,
                "queue_length": queue_length,
                "online_drivers": online,
                "offline_drivers": offline,
                "drivers_on_trip": on_trip,
                "available_drivers": available,
                "active_trips": trips.exclude(
                    status__in=[
                        TripStatus.COMPLETED,
                        TripStatus.CANCELLED,
                        TripStatus.PAYMENT_CONFIRMED,
                        TripStatus.SETTLED,
                    ]
                ).count(),
                "completed_today": completed_today,
                "cancelled_today": cancelled_today,
                "average_waiting_seconds": avg_wait,
                "gross_fare_today_minor": trips.filter(
                    completed_at__date=today,
                    payment_transaction__isnull=False,
                ).aggregate(total=Sum("fare_minor"))["total"]
                or 0,
                "open_alerts": open_alerts,
                "station_health": health,
                "performance": {
                    "completion_rate_e4": completion_rate,
                    "utilization_e4": utilization,
                    "requested_today": requested_today,
                },
            }
        )


@extend_schema(
    tags=["mobility-notifications"],
    responses=MobilityNotificationSerializer(many=True),
)
class MobilityNotificationListView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        rows = MobilityNotification.objects.filter(
            recipient_principal=request.auth.owner
        ).order_by("-created_at")[:100]
        return Response(MobilityNotificationSerializer(rows, many=True).data)


@extend_schema(
    tags=["mobility-regulatory"],
    request=RegulatoryReportRequestSerializer,
    responses=RegulatoryReportResponseSerializer,
)
class RegulatoryReportView(APIView):
    permission_classes = [IsDevice, CanViewRegulatory]

    def post(self, request):
        start = request.data.get("period_start")
        end = request.data.get("period_end")
        if not start or not end:
            return Response({"detail": "period_start and period_end required"}, status=400)
        qs = Trip.objects.filter(created_at__date__gte=start, created_at__date__lte=end)
        payload = {
            "trips": qs.count(),
            "completed": qs.filter(status__in=[TripStatus.COMPLETED, TripStatus.PAYMENT_CONFIRMED, TripStatus.SETTLED]).count(),
            "cancelled": qs.filter(status=TripStatus.CANCELLED).count(),
            "safety_incidents": SafetyIncident.objects.filter(
                created_at__date__gte=start, created_at__date__lte=end
            ).count(),
            "active_drivers": Driver.objects.filter(status=DriverStatus.ACTIVE).count(),
            "verified_vehicles": Vehicle.objects.filter(
                inspection_status=VerificationStatus.VERIFIED
            ).count(),
        }
        report = MobilityRegulatoryReport.objects.create(
            report_type=request.data.get("report_type", "transport_authority"),
            authority=request.data.get("authority", "LATRA"),
            period_start=start,
            period_end=end,
            payload=payload,
        )
        return Response({"id": str(report.id), "payload": payload}, status=201)


@extend_schema(
    tags=["mobility-intelligence"],
    responses=MobilityIntelligenceSerializer,
)
class MobilityIntelligenceView(APIView):
    permission_classes = [IsDevice, IsMobilityOperator]

    def get(self, request, kind):
        if kind == "demand":
            station = get_object_or_404(Station, pk=request.query_params.get("station_id"))
            forecast = forecast_station_demand(
                station,
                horizon_minutes=int(request.query_params.get("horizon_minutes", 60)),
            )
            return Response(forecast.__dict__)
        if kind == "city_demand":
            region = request.query_params.get("region", "").strip()
            if not region:
                return Response({"detail": "region required"}, status=400)
            from .intelligence import forecast_city_demand

            return Response(
                forecast_city_demand(
                    region=region,
                    district=request.query_params.get("district", "").strip(),
                    horizon_minutes=int(request.query_params.get("horizon_minutes", 60)),
                )
            )
        if kind == "positioning":
            station = get_object_or_404(Station, pk=request.query_params.get("station_id"))
            return Response(driver_positioning_recommendations(station))
        if kind == "maintenance":
            vehicle = get_object_or_404(Vehicle, pk=request.query_params.get("vehicle_id"))
            return Response(maintenance_prediction(vehicle))
        if kind == "fraud":
            trip = get_object_or_404(Trip, pk=request.query_params.get("trip_id"))
            from .intelligence import trip_fraud_signals

            return Response(trip_fraud_signals(trip))
        if kind == "load_balance":
            region = request.query_params.get("region", "").strip()
            if not region:
                return Response({"detail": "region required"}, status=400)
            from .city_ops import load_balance_recommendations

            return Response(
                {
                    "recommendations": load_balance_recommendations(
                        region=region,
                        district=request.query_params.get("district", "").strip(),
                    )
                }
            )
        return Response({"detail": "unknown intelligence module"}, status=404)
