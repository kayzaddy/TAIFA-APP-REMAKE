"""Tourism assistance — SOS and nearby help (TAIFA-TOUR-007)."""
from __future__ import annotations

from django.db import transaction

from trips.models import SafetyIncident

from .models import TourismAssistanceCase, TourismAssistanceStatus, TourismTrip


class TourismAssistError(Exception):
    pass


NEARBY_SEED = [
    {
        "id": "hosp-muhimbili",
        "kind": "hospital",
        "name": "Muhimbili National Hospital",
        "phone": "+255 22 215 0000",
        "distance_km": 2.4,
    },
    {
        "id": "police-central",
        "kind": "police",
        "name": "Central Police Station — Dar",
        "phone": "112",
        "distance_km": 1.1,
    },
    {
        "id": "emb-us",
        "kind": "embassy",
        "name": "U.S. Embassy Dar es Salaam",
        "phone": "+255 22 229 4000",
        "distance_km": 5.8,
    },
    {
        "id": "pharm-ag",
        "kind": "pharmacy",
        "name": "Agakhan Pharmacy",
        "phone": "+255 22 211 5151",
        "distance_km": 0.9,
    },
]


def nearby_assistance(*, latitude: float | None = None, longitude: float | None = None) -> dict:
    del latitude, longitude  # MVP static list; geo sort in phase 2
    return {
        "places": NEARBY_SEED,
        "model_version": "tourism.assist.nearby.v1",
    }


@transaction.atomic
def open_tourism_sos(
    *,
    owner: str,
    trip: TourismTrip | None = None,
    latitude: float | None = None,
    longitude: float | None = None,
    notes: str = "",
) -> TourismAssistanceCase:
    incident = SafetyIncident.objects.create(
        reporter_principal=owner,
        kind="sos",
        severity="critical",
        latitude=latitude,
        longitude=longitude,
        details={
            "context": "tourism",
            "trip_id": str(trip.id) if trip else "",
            "notes": notes,
        },
    )
    case = TourismAssistanceCase.objects.create(
        owner=owner,
        trip=trip,
        kind="sos",
        status=TourismAssistanceStatus.OPEN,
        latitude=latitude,
        longitude=longitude,
        notes=notes,
        safety_incident_id=incident.id,
    )
    return case


def assistance_case_to_dict(case: TourismAssistanceCase) -> dict:
    return {
        "id": str(case.id),
        "trip_id": str(case.trip_id) if case.trip_id else None,
        "kind": case.kind,
        "status": case.status,
        "latitude": float(case.latitude) if case.latitude is not None else None,
        "longitude": float(case.longitude) if case.longitude is not None else None,
        "notes": case.notes,
        "safety_incident_id": str(case.safety_incident_id) if case.safety_incident_id else None,
        "created_at": case.created_at.isoformat(),
        "model_version": "tourism.assist.case.v1",
    }
