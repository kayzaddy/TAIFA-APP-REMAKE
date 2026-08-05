# Government Integration Guide

## Principle

All authority connectivity uses **adapter interfaces**. Application code calls `government_adapter(authority)`; it never hardcodes LATRA/TANROADS/etc. HTTP clients.

## Configuration

```bash
# Optional JSON map: authority code → dotted class path
export MOBILITY_GOVERNMENT_ADAPTERS_JSON='{
  "LATRA": "trips.adapters.government.LatraAdapter",
  "TANROADS": "trips.adapters.government.TanroadsAdapter"
}'
```

Empty / missing keys fall back to built-in defaults (stub adapters that accept and echo payloads). Replace stubs with live classes when credentials and network paths are available.

## Supported authority codes

| Code | Purpose |
| --- | --- |
| LATRA | Land transport regulation statistics |
| TANROADS | Trunk road / corridor metrics |
| TARURA | Urban roads / municipal transport |
| LGA | Local Government Authority reports |
| TRA | Tax / fiscal transport aggregates (refs only) |
| POLICE | Safety / escort readiness (future live) |
| EMERGENCY | Emergency services coordination |
| NIDA | Identity cross-checks (adapter reserved) |
| BRELA | Business registry for operators (adapter reserved) |
| TRAFFIC | Traffic management feeds |

## Reporting API

`POST /api/v1/trips/national/reports`

```json
{
  "authority": "LATRA",
  "period_start": "2026-01-01",
  "period_end": "2026-01-31"
}
```

Flow:

1. Build `national_analytics` (90-day lookback default in view).
2. Resolve adapter via settings.
3. `submit_transport_statistics(...)`.
4. Persist `MobilityRegulatoryReport` with adapter reference.

## Implementing a live adapter

```python
class LatraLiveAdapter:
    authority_code = "LATRA"

    def submit_transport_statistics(self, *, period_start, period_end, payload):
        # TLS mTLS / API key to LATRA gateway
        return GovernmentReportResult(
            authority="LATRA",
            accepted=True,
            reference=response["id"],
            payload=response,
        )
```

Register the path in `MOBILITY_GOVERNMENT_ADAPTERS_JSON`.

## Security

- Prefer outbound-only aggregates (no raw passenger PII).
- Store authority references, not credentials, in report rows.
- Rotate partner and authority secrets outside the Mobility DB.
