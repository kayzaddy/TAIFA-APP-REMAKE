"""WebSocket fan-out helpers for live trip/driver tracking."""
from __future__ import annotations

from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from django.db import transaction


def trip_group(trip_id) -> str:
    return f"mobility.trip.{trip_id}"


def broadcast_trip(trip_id, event_type: str, payload: dict) -> None:
    """Publish after DB commit so clients never observe rolled-back state."""

    def send() -> None:
        layer = get_channel_layer()
        if layer is None:
            return
        async_to_sync(layer.group_send)(
            trip_group(trip_id),
            {
                "type": "mobility.message",
                "event": event_type,
                "payload": payload,
            },
        )

    transaction.on_commit(send)
