"""City-scale mobility API views — map, regional KPIs, fleet intelligence, incidents."""
from __future__ import annotations

from django.shortcuts import get_object_or_404
from django.utils import timezone
from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework.response import Response
from rest_framework.views import APIView

from payments.auth import IsDevice

from .city_ops import (
    city_map_snapshot,
    fleet_intelligence,
    load_balance_recommendations,
    overflow_candidate_stations,
    rank_stations,
    regional_kpis,
    station_intelligence,
)
from .intelligence import (
    driver_performance,
    forecast_city_demand,
    rank_drivers_city,
)
from .models import (
    Driver,
    Fleet,
    SafetyIncident,
    Station,
)
from .permissions import IsMobilityOperator
from .serializers import SafetyIncidentSerializer
from .services import MobilityError, transition_incident


def _bbox(request):
    raw = request.query_params.get("bbox")
    if not raw:
        return None
    parts = [float(p.strip()) for p in raw.split(",")]
    if len(parts) != 4:
        return None
    return tuple(parts)  # min_lat, min_lng, max_lat, max_lng


@extend_schema(
    tags=["mobility-city"],
    parameters=[
        OpenApiParameter("region", str, required=True),
        OpenApiParameter("district", str, required=False),
        OpenApiParameter("bbox", str, required=False, description="min_lat,min_lng,max_lat,max_lng"),
    ],
)
class CityMapView(APIView):
    permission_classes = [IsDevice, IsMobilityOperator]

    def get(self, request):
        region = request.query_params.get("region", "").strip()
        if not region:
            return Response({"detail": "region required"}, status=400)
        return Response(
            city_map_snapshot(
                region=region,
                district=request.query_params.get("district", "").strip(),
                bbox=_bbox(request),
            )
        )


@extend_schema(
    tags=["mobility-city"],
    parameters=[
        OpenApiParameter("region", str, required=True),
        OpenApiParameter("district", str, required=False),
    ],
)
class CityOperationsView(APIView):
    permission_classes = [IsDevice, IsMobilityOperator]

    def get(self, request):
        region = request.query_params.get("region", "").strip()
        if not region:
            return Response({"detail": "region required"}, status=400)
        district = request.query_params.get("district", "").strip()
        kpis = regional_kpis(region=region, district=district)
        rankings = rank_stations(region=region, district=district, limit=20)
        balance = load_balance_recommendations(region=region, district=district)
        demand = forecast_city_demand(region=region, district=district)
        return Response(
            {
                "kpis": kpis,
                "station_rankings": rankings,
                "load_balance": balance,
                "demand": {
                    "predicted_requests_total": demand["predicted_requests_total"],
                    "hotspots": demand["hotspots"][:10],
                    "model_version": demand["model_version"],
                },
                "generated_at": timezone.now().isoformat(),
            }
        )


@extend_schema(tags=["mobility-stations"])
class StationIntelligenceView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, station_id):
        station = get_object_or_404(Station, pk=station_id)
        actor = request.auth.owner
        if station.manager_principal != actor and not _is_ops(request):
            return Response({"detail": "station intelligence access denied"}, status=403)
        payload = station_intelligence(station)
        payload["overflow_candidates"] = overflow_candidate_stations(station)
        return Response(payload)


@extend_schema(
    tags=["mobility-stations"],
    parameters=[
        OpenApiParameter("region", str, required=False),
        OpenApiParameter("district", str, required=False),
    ],
)
class StationRankingsView(APIView):
    permission_classes = [IsDevice, IsMobilityOperator]

    def get(self, request):
        return Response(
            {
                "rankings": rank_stations(
                    region=request.query_params.get("region", "").strip(),
                    district=request.query_params.get("district", "").strip(),
                    limit=int(request.query_params.get("limit", 50)),
                )
            }
        )


@extend_schema(tags=["mobility-fleets"])
class FleetIntelligenceView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, fleet_id):
        fleet = get_object_or_404(Fleet, pk=fleet_id)
        if fleet.owner_principal != request.auth.owner and not _is_ops(request):
            return Response({"detail": "fleet access denied"}, status=403)
        return Response(fleet_intelligence(fleet))


@extend_schema(tags=["mobility-drivers"], operation_id="trips_driver_performance_self")
class DriverPerformanceSelfView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        driver = get_object_or_404(Driver, owner_principal=request.auth.owner)
        return Response(driver_performance(driver))


@extend_schema(tags=["mobility-drivers"], operation_id="trips_driver_performance_detail")
class DriverPerformanceDetailView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, driver_id):
        driver = get_object_or_404(Driver, pk=driver_id)
        if driver.owner_principal != request.auth.owner and not _is_ops(request):
            return Response({"detail": "driver performance access denied"}, status=403)
        return Response(driver_performance(driver))


@extend_schema(tags=["mobility-drivers"])
class DriverPerformanceView(APIView):
    """Deprecated alias — use DriverPerformanceSelfView / DriverPerformanceDetailView."""

    permission_classes = [IsDevice]

    def get(self, request, driver_id=None):
        if driver_id:
            return DriverPerformanceDetailView().get(request, driver_id)
        return DriverPerformanceSelfView().get(request)


@extend_schema(
    tags=["mobility-drivers"],
    parameters=[
        OpenApiParameter("region", str, required=True),
        OpenApiParameter("district", str, required=False),
    ],
)
class DriverCityRankingsView(APIView):
    permission_classes = [IsDevice, IsMobilityOperator]

    def get(self, request):
        region = request.query_params.get("region", "").strip()
        if not region:
            return Response({"detail": "region required"}, status=400)
        return Response(
            {
                "rankings": rank_drivers_city(
                    region=region,
                    district=request.query_params.get("district", "").strip(),
                    limit=int(request.query_params.get("limit", 50)),
                )
            }
        )


@extend_schema(tags=["mobility-safety"], responses=SafetyIncidentSerializer(many=True))
class SafetyIncidentListView(APIView):
    permission_classes = [IsDevice, IsMobilityOperator]

    def get(self, request):
        qs = SafetyIncident.objects.all().order_by("-created_at")
        status_value = request.query_params.get("status")
        region = request.query_params.get("region", "").strip()
        if status_value:
            qs = qs.filter(status=status_value)
        if region:
            qs = qs.filter(trip__station__region__iexact=region)
        kind = request.query_params.get("kind")
        if kind:
            qs = qs.filter(kind=kind)
        return Response(SafetyIncidentSerializer(qs[:200], many=True).data)


@extend_schema(tags=["mobility-safety"], request=None, responses=SafetyIncidentSerializer)
class SafetyIncidentDetailView(APIView):
    permission_classes = [IsDevice, IsMobilityOperator]

    def get(self, request, incident_id):
        incident = get_object_or_404(SafetyIncident, pk=incident_id)
        return Response(SafetyIncidentSerializer(incident).data)

    def patch(self, request, incident_id):
        to_status = request.data.get("status")
        if not to_status:
            return Response({"detail": "status required"}, status=400)
        try:
            incident = transition_incident(
                incident_id,
                to_status=to_status,
                actor=request.auth.owner,
                assigned_to=str(request.data.get("assigned_to", "")),
                notes=str(request.data.get("notes", "")),
            )
        except MobilityError as exc:
            return Response({"detail": str(exc)}, status=409)
        except SafetyIncident.DoesNotExist:
            return Response({"detail": "not found"}, status=404)
        return Response(SafetyIncidentSerializer(incident).data)


@extend_schema(
    tags=["mobility-analytics"],
    parameters=[
        OpenApiParameter("region", str, required=True),
        OpenApiParameter("district", str, required=False),
    ],
)
class CityAnalyticsView(APIView):
    permission_classes = [IsDevice, IsMobilityOperator]

    def get(self, request):
        region = request.query_params.get("region", "").strip()
        if not region:
            return Response({"detail": "region required"}, status=400)
        district = request.query_params.get("district", "").strip()
        return Response(
            {
                "kpis": regional_kpis(region=region, district=district),
                "stations": rank_stations(region=region, district=district, limit=25),
                "drivers": rank_drivers_city(region=region, district=district, limit=25),
                "demand": forecast_city_demand(region=region, district=district),
                "load_balance": load_balance_recommendations(region=region, district=district),
            }
        )


def _is_ops(request) -> bool:
    from .permissions import has_permission

    return has_permission(request, "mobility.operations")
