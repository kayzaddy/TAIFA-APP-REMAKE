"""WebSocket fan-out for BRT / transit AVL (Phase 3)."""
from __future__ import annotations

from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from django.db import transaction


def transit_avl_group(*, region: str = "", route_id: str = "") -> str:
    if route_id:
        return f"mobility.transit.avl.route.{route_id}"
    slug = (region or "all").lower().replace(" ", "-")
    return f"mobility.transit.avl.region.{slug}"


def broadcast_transit_avl(
    *,
    region: str,
    route_id: str,
    event_type: str,
    payload: dict,
) -> None:
    def send() -> None:
        layer = get_channel_layer()
        if layer is None:
            return
        message = {
            "type": "mobility.message",
            "event": event_type,
            "payload": payload,
        }
        async_to_sync(layer.group_send)(transit_avl_group(region=region), message)
        if route_id:
            async_to_sync(layer.group_send)(transit_avl_group(route_id=route_id), message)

    transaction.on_commit(send)
