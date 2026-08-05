# Taifa Mobility Hybrid Dispatch — API

Base path: `/api/v1/mobility-channels/`

## Webhooks (telco aggregators)

### POST `/webhooks/sms/inbound`

Inbound SMS. No auth (configure IP allow-list at gateway).

```json
{ "from": "+255712345678", "text": "YES" }
```

Actions: `YES`/`1` accept · `NO`/`2` reject · `REGISTER {Name} {Stage} {Vehicle}`

### POST `/webhooks/ussd`

Africa's Talking style USSD callback.

```json
{ "phoneNumber": "+255712345678", "text": "2" }
```

Response: `{ "response": "END …" }` or `CON …` menu text.

### POST `/webhooks/ivr/dtmf`

```json
{ "offer_id": "uuid", "digit": "1" }
```

Digits: `1` accept · `2` decline · `3` unavailable

## Authenticated (device token)

### POST `/drivers/bind`

Bind driver to MSISDN and device profile.

```json
{
  "driver_id": "uuid",
  "msisdn": "+255712345678",
  "device_capability": "feature_phone",
  "has_internet": false,
  "has_gps": false
}
```

### GET `/trips/{trip_id}/status`

Passenger-scoped hybrid status (owner must match trip).

```json
{
  "trip_id": "…",
  "status": "searching",
  "message": "Finding your nearest driver…",
  "driver_name": "",
  "vehicle_label": ""
}
```

### POST `/trips/{trip_id}/verify-pin`

```json
{ "pin": "482910" }
```

### POST `/stations/{station_id}/dispatch`

Stage dispatcher manual re-dispatch.

```json
{ "trip_id": "uuid" }
```

## SMS templates

**Driver offer**

```
TAIFA MOBILITY

New Ride Request

Passenger:
{Name}

Pickup:
{Pickup}

Destination:
{Destination}

Estimated Fare:
{Fare}

Reply YES or 1 within 30 seconds to accept.

Ride ID:
{RideID}
```

**Passenger accepted**

```
Your ride has been accepted.

Driver:
{Name}

Phone:
{Phone}

Vehicle:
{Registration}

Estimated Arrival:
{ETA} min

Trip PIN: {PIN}
```
