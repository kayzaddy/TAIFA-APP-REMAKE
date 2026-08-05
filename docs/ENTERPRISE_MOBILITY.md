# Enterprise Mobility Guide

## Who it serves

Corporate fleets, NGOs, hospitals, universities, factories, mining, construction, and government agencies operating on the same national mobility fabric.

## Core objects

| Model | Role |
| --- | --- |
| `EnterpriseOrganization` | Org code, type, billing account, policy JSON, optional fleet link |
| `EnterpriseEmployee` | Principal enrollment + department |

Policy example:

```json
{
  "allowed_departments": ["HR", "Ops", "Field"],
  "max_daily_trips": 50,
  "vehicle_modes": ["taxi", "van", "bus"]
}
```

## APIs

| Method | Path | Notes |
| --- | --- | --- |
| GET/POST | `/api/v1/trips/enterprise/organizations` | List / create org |
| GET/POST | `/api/v1/trips/enterprise/organizations/{id}/employees` | Enroll staff |
| POST | `/api/v1/trips/enterprise/trips` | Authorize + create trip under org policy |

Authorization uses `authorize_enterprise_trip` — employees must be active; departments must match policy when `allowed_departments` is set.

## Billing

Department and corporate billing **references** Taifa Payments accounts via `billing_account` / trip `payment_ref`. Mobility does not post ledgers.

## Usage reports

Use national analytics filtered by region plus enterprise trip metadata (`kind=corporate`, corporate account on pricing rules from Phase 2). Fleet intelligence endpoints remain available for linked fleets.

## Route optimization

National optimization (`/national/optimization`) and city load-balance recommendations apply to enterprise demand the same way as public demand — no parallel optimizer.
