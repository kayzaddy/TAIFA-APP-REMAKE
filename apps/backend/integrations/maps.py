"""Maps / GIS — geocoding and routing via configurable HTTP providers."""
from __future__ import annotations

from dataclasses import dataclass

from django.conf import settings

from .http_client import IntegrationHttpClient, IntegrationHttpError


@dataclass(frozen=True)
class GeoPoint:
    lat: float
    lng: float


@dataclass(frozen=True)
class RouteResult:
    distance_m: float
    duration_s: float
    geometry: dict
    provider: str


class MapsNotConfigured(RuntimeError):
    pass


class HttpMapsAdapter:
    """Generic maps adapter (Google / Mapbox / OSRM style via config).

    TAIFA_MAPS_PROVIDER_JSON:
      {
        "base_url": "https://api.mapbox.com",
        "api_key": "...",
        "geocode_path": "/geocoding/v5/mapbox.places/{query}.json",
        "route_path": "/directions/v5/mapbox/driving/{coords}",
        "provider": "mapbox"
      }
    """

    def __init__(self):
        cfg = getattr(settings, "TAIFA_MAPS_PROVIDER", None) or {}
        base_url = (cfg.get("base_url") or "").strip()
        if not base_url:
            raise MapsNotConfigured("maps provider not configured (TAIFA_MAPS_PROVIDER_JSON)")
        self.provider = cfg.get("provider", "http_maps")
        self._api_key = cfg.get("api_key") or ""
        self._geocode_path = cfg.get("geocode_path", "/geocode")
        self._route_path = cfg.get("route_path", "/route")
        self._client = IntegrationHttpClient(
            integration=f"maps.{self.provider}",
            base_url=base_url,
            timeout_s=float(cfg.get("timeout_seconds", 15)),
            default_headers={"Accept": "application/json"},
        )

    def geocode(self, *, query: str) -> GeoPoint:
        path = self._geocode_path.replace("{query}", requests_quote(query))
        params = {}
        if self._api_key:
            params["access_token"] = self._api_key
            params["key"] = self._api_key
        try:
            resp = self._client.request("GET", path, operation="geocode", params=params)
            data = resp.json()
        except IntegrationHttpError as exc:
            raise RuntimeError(f"geocode failed: {exc}") from exc
        # Mapbox features / Google results / generic {lat,lng}
        if "features" in data and data["features"]:
            coords = data["features"][0]["center"]
            return GeoPoint(lat=float(coords[1]), lng=float(coords[0]))
        if "results" in data and data["results"]:
            loc = data["results"][0].get("geometry", {}).get("location", {})
            return GeoPoint(lat=float(loc["lat"]), lng=float(loc["lng"]))
        return GeoPoint(lat=float(data["lat"]), lng=float(data["lng"]))

    def reverse_geocode(self, *, lat: float, lng: float) -> str:
        path = self._geocode_path.replace("{query}", f"{lng},{lat}")
        params = {}
        if self._api_key:
            params["access_token"] = self._api_key
            params["key"] = self._api_key
        resp = self._client.request("GET", path, operation="reverse_geocode", params=params)
        data = resp.json()
        if "features" in data and data["features"]:
            return str(data["features"][0].get("place_name") or "")
        if "results" in data and data["results"]:
            return str(data["results"][0].get("formatted_address") or "")
        return str(data.get("display_name") or data.get("address") or "")

    def route(self, *, origin: GeoPoint, destination: GeoPoint) -> RouteResult:
        coords = f"{origin.lng},{origin.lat};{destination.lng},{destination.lat}"
        path = self._route_path.replace("{coords}", coords)
        params = {"geometries": "geojson", "overview": "full"}
        if self._api_key:
            params["access_token"] = self._api_key
            params["key"] = self._api_key
        resp = self._client.request("GET", path, operation="route", params=params)
        data = resp.json()
        # Mapbox / OSRM
        routes = data.get("routes") or []
        if routes:
            r0 = routes[0]
            return RouteResult(
                distance_m=float(r0.get("distance") or 0),
                duration_s=float(r0.get("duration") or 0),
                geometry=r0.get("geometry") or {},
                provider=self.provider,
            )
        raise RuntimeError("maps provider returned no routes")


def requests_quote(value: str) -> str:
    from urllib.parse import quote

    return quote(value, safe="")
