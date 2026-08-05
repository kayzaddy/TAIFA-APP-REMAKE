"""Authenticated WebSocket consumers for mobility trip and transit AVL tracking."""
from __future__ import annotations

from channels.db import database_sync_to_async
from channels.generic.websocket import AsyncJsonWebsocketConsumer

from payments.auth import hash_token
from payments.models import Device

from .models import Trip
from .realtime import trip_group
from . import transit_services as transit_svc
from .transit_realtime import transit_avl_group


def _headers(scope) -> dict[str, str]:
    return {
        key.decode("latin-1").lower(): value.decode("latin-1")
        for key, value in scope.get("headers", [])
    }


@database_sync_to_async
def _authorize(scope, trip_id) -> tuple[bool, str]:
    headers = _headers(scope)
    auth = headers.get("authorization", "")
    device_id = headers.get("x-device-id", "")
    parts = auth.split()
    if len(parts) != 2 or parts[0].lower() != "bearer" or not device_id:
        return False, ""
    try:
        device = Device.objects.get(
            token_hash=hash_token(parts[1]),
            device_id=device_id,
        )
        trip = Trip.objects.select_related("driver").get(pk=trip_id)
    except (Device.DoesNotExist, Trip.DoesNotExist):
        return False, ""
    allowed = device.owner == trip.owner or (
        trip.driver_id and trip.driver.owner_principal == device.owner
    )
    return bool(allowed), device.owner


class TripTrackingConsumer(AsyncJsonWebsocketConsumer):
    async def connect(self):
        self.trip_id = self.scope["url_route"]["kwargs"]["trip_id"]
        allowed, owner = await _authorize(self.scope, self.trip_id)
        if not allowed:
            await self.close(code=4403)
            return
        self.owner = owner
        self.group_name = trip_group(self.trip_id)
        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()
        await self.send_json({"event": "mobility.connected", "trip_id": str(self.trip_id)})

    async def disconnect(self, close_code):
        if hasattr(self, "group_name"):
            await self.channel_layer.group_discard(self.group_name, self.channel_name)

    async def receive_json(self, content, **kwargs):
        # Server-authoritative channel. Clients may ping, never mutate trip state.
        if content.get("type") == "ping":
            await self.send_json({"event": "pong"})

    async def mobility_message(self, event):
        await self.send_json(
            {
                "event": event["event"],
                "payload": event.get("payload", {}),
            }
        )


@database_sync_to_async
def _device_owner(scope) -> str | None:
    headers = _headers(scope)
    auth = headers.get("authorization", "")
    device_id = headers.get("x-device-id", "")
    parts = auth.split()
    if len(parts) != 2 or parts[0].lower() != "bearer" or not device_id:
        return None
    try:
        device = Device.objects.get(
            token_hash=hash_token(parts[1]),
            device_id=device_id,
        )
    except Device.DoesNotExist:
        return None
    return device.owner


def _region_from_slug(slug: str) -> str:
    return slug.replace("-", " ").title().replace("Dar Es Salaam", "Dar es Salaam")


class TransitAvlConsumer(AsyncJsonWebsocketConsumer):
    """Live BRT vehicle positions for a region (Phase 3)."""

    async def connect(self):
        slug = self.scope["url_route"]["kwargs"].get("region_slug", "dar-es-salaam")
        self.region = _region_from_slug(slug)
        owner = await _device_owner(self.scope)
        if not owner:
            await self.close(code=4403)
            return
        self.owner = owner
        self.group_name = transit_avl_group(region=self.region)
        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()
        snapshot = await database_sync_to_async(transit_svc.live_transit_map)(region=self.region)
        await self.send_json({"event": "transit.avl.snapshot", "payload": snapshot})

    async def disconnect(self, close_code):
        if hasattr(self, "group_name"):
            await self.channel_layer.group_discard(self.group_name, self.channel_name)

    async def receive_json(self, content, **kwargs):
        if content.get("type") == "ping":
            await self.send_json({"event": "pong"})

    async def mobility_message(self, event):
        await self.send_json(
            {
                "event": event["event"],
                "payload": event.get("payload", {}),
            }
        )
