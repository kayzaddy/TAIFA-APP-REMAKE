# Taifa Mobility Hybrid Dispatch — PRD

## Vision

Build Africa's most inclusive ride-hailing platform — starting in Tanzania — where **smartphone and feature-phone drivers** operate in one network without passengers knowing which channel was used.

## Problem

Uber/Bolt assume smartphone + data for every driver. In Tanzania, large segments of riders (boda, taxi, van) use feature phones or intermittent connectivity. Lost offers mean lost income and unreliable service.

## Solution

A **hybrid dispatch control plane** (`mobility_channels`) that sits on top of the existing `trips` dispatch engine and automatically selects the best outreach channel per driver.

### Channel priority

1. Push notification (smartphone + data)
2. SMS
3. USSD (`*150*99#` menu)
4. Automated voice (IVR / DTMF)
5. Stage dispatcher manual assignment

## Personas

| Persona | Device | Need |
| --- | --- | --- |
| Urban passenger | Smartphone | One-tap ride, opaque dispatch |
| Rural passenger | Smartphone or feature phone | Reliable pickup |
| Smartphone driver | App + GPS | Push offers, navigation |
| Feature-phone driver | SMS/USSD/voice | Accept rides without data |
| Stage dispatcher | Dashboard / station ops | Manual fallback, queue control |

## Core flows

### Passenger (transparent)

1. Tap **Request Ride**
2. See *"Finding your nearest driver…"* (polls `/mobility-channels/trips/{id}/status`)
3. Driver assigned → ETA, contact, trip PIN
4. Trip proceeds (existing Mobility lifecycle)

### Feature-phone driver

1. Receive SMS offer with pickup, destination, fare, ride ID
2. Reply `YES` or `1` within 30 seconds
3. Receive passenger phone number via SMS
4. Voice coordination → arrive → enter boarding PIN

### Stage fallback

If no driver responds, notify station manager via `mobility.stage.dispatch_needed` and expose manual dispatch API.

## Security

- 6-digit boarding PIN (hashed at rest)
- SOS / incident hooks via existing `trips` safety module
- MSISDN hashed in inbound audit logs
- RBAC via device-bound auth for passenger/station APIs

## Non-goals (this phase)

- Replacing Django/FastAPI split (extend existing stack)
- Duplicating payments, wallet, or ledger
- Full AI demand prediction (reuse `trips.intelligence` later)
- Production telco contracts (adapters are gateway-ready)

## Success metrics

- Offer delivery rate by channel
- SMS/USSD accept latency (< 30s)
- Stage fallback rate (target ↓ over time)
- Passenger NPS (channel invisible)
