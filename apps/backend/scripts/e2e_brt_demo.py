"""Run Taifa Mobility BRT Phase 1 E2E against a live backend."""
from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.request
import uuid

import django

BASE = "http://127.0.0.1:8000/api/v1"


def req(method: str, path: str, body: dict | None = None, headers: dict | None = None):
    h = {"Content-Type": "application/json", **(headers or {})}
    data = None if body is None else json.dumps(body).encode()
    request = urllib.request.Request(BASE + path, data=data, headers=h, method=method)
    try:
        with urllib.request.urlopen(request, timeout=20) as resp:
            raw = resp.read().decode()
            return resp.status, json.loads(raw) if raw else {}
    except urllib.error.HTTPError as exc:
        raw = exc.read().decode()
        try:
            payload = json.loads(raw) if raw else {"detail": raw}
        except json.JSONDecodeError:
            payload = {"detail": raw}
        return exc.code, payload


def main() -> int:
    print("=== Taifa Mobility BRT E2E Demo ===\n")

    device_id = f"brt-e2e-{uuid.uuid4().hex[:8]}"
    code, reg = req(
        "POST",
        "/auth/device/register",
        {"device_id": device_id, "platform": "windows"},
    )
    print(f"1. Device register: HTTP {code}")
    if code not in (200, 201):
        print(json.dumps(reg, indent=2))
        return 1
    token = reg["token"]
    owner = reg["owner"]
    auth = {"Authorization": f"Bearer {token}", "X-Device-Id": device_id}
    print(f"   owner={owner}")

    code, wallet = req("GET", "/payments/wallet", headers=auth)
    bal = wallet.get("balance_minor", 0) / 100
    print(f"2. Wallet balance: HTTP {code} -> TSh {bal:,.0f}")

    code, home = req(
        "GET",
        "/trips/transit/home?lat=-6.7912&lng=39.2089&region=Dar%20es%20Salaam",
        headers=auth,
    )
    print(f"3. Transit home: HTTP {code}")
    if code != 200:
        print(json.dumps(home, indent=2))
        return 1
    print(
        f"   stations={len(home.get('nearby_stations', []))}, "
        f"routes={len(home.get('featured_routes', []))}, "
        f"alerts={len(home.get('alerts', []))}"
    )
    route = home["featured_routes"][0]
    route_id = route["id"]
    print(f"   featured route: {route.get('name')} ({route.get('code')})")

    code, detail = req("GET", f"/trips/transit/routes/{route_id}", headers=auth)
    print(
        f"4. Route detail: HTTP {code}, stops={len(detail.get('stops', []))}, "
        f"departures={len(detail.get('departures', []))}"
    )

    idem = f"e2e-brt-{uuid.uuid4().hex}"
    code, ticket = req(
        "POST",
        "/trips/transit/tickets/purchase",
        {
            "route_id": route_id,
            "product_code": "brt_single",
            "origin_stop": "kimara",
            "destination_stop": "kivukoni",
        },
        headers={**auth, "Idempotency-Key": idem},
    )
    print(f"5. Purchase ticket: HTTP {code}")
    if code != 201:
        print(json.dumps(ticket, indent=2))
        return 1
    media = ticket["media_code"]
    fare = ticket.get("fare_minor", 0) / 100
    print(f"   media_code={media}, fare=TSh {fare:,.0f}, payment_ref={ticket.get('payment_ref')}")

    code, wallet2 = req("GET", "/payments/wallet", headers=auth)
    bal2 = wallet2.get("balance_minor", 0) / 100
    print(f"6. Wallet after purchase: HTTP {code} -> TSh {bal2:,.0f} (delta TSh {bal - bal2:,.0f})")

    code, mine = req("GET", "/trips/transit/tickets/mine", headers=auth)
    print(f"7. My tickets: HTTP {code}, count={len(mine.get('tickets', []))}")

    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
    django.setup()
    from enterprise.models import PlatformPrincipal, PlatformRole

    v_device = f"brt-validator-e2e-{uuid.uuid4().hex[:8]}"
    code, vreg = req(
        "POST",
        "/auth/device/register",
        {"device_id": v_device, "platform": "windows"},
    )
    role = PlatformRole.objects.get(code="transit-validator")
    principal, _ = PlatformPrincipal.objects.get_or_create(
        principal_id=vreg["owner"],
        defaults={"display_name": "E2E Validator", "mfa_required": False},
    )
    principal.roles.add(role)
    vauth = {"Authorization": f"Bearer {vreg['token']}", "X-Device-Id": v_device}

    code, ok = req(
        "POST",
        "/trips/transit/tickets/validate",
        {"media_code": media, "qr": ticket.get("qr")},
        headers=vauth,
    )
    print(f"8. Validate (1st): HTTP {code}, valid={ok.get('valid')}")

    code, replay = req(
        "POST",
        "/trips/transit/tickets/validate",
        {"media_code": media, "qr": ticket.get("qr")},
        headers=vauth,
    )
    print(f"9. Validate (replay): HTTP {code} -> {replay.get('detail', replay)}")

    if code != 400:
        return 1

    print("\n=== E2E DEMO PASSED ===")
    return 0


if __name__ == "__main__":
    sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    raise SystemExit(main())
