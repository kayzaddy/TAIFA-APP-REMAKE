# Taifa Mobility Hybrid Dispatch — User Stories

## Passenger

| ID | Story | Acceptance |
| --- | --- | --- |
| P1 | As a passenger, I tap Request Ride and see a single searching message | UI shows *Finding your nearest driver…*; polls hybrid status |
| P2 | As a passenger, I never see whether the driver was reached by SMS or push | Status API returns channel-agnostic `message` only |
| P3 | As a passenger, I receive driver contact and trip PIN after accept | SMS when `trip.metadata.passenger_msisdn` set; in-app notification |

## Feature-phone driver

| ID | Story | Acceptance |
| --- | --- | --- |
| D1 | As a feature-phone driver, I register via SMS | `REGISTER JOHN MWENGE BOXER` creates driver + binding |
| D2 | As a feature-phone driver, I accept via SMS YES | Pending offer accepted; passenger notified |
| D3 | As a feature-phone driver, I accept via USSD menu option 2 | Same as D2 |
| D4 | As a feature-phone driver, I get passenger number after accept | Outbound SMS to driver MSISDN |

## Smartphone driver

| ID | Story | Acceptance |
| --- | --- | --- |
| S1 | As a smartphone driver, I receive push offers | `notify_mobility` event `mobility.dispatch.offer` |
| S2 | As a smartphone driver, I fall back to IVR if I miss SMS | Celery task at T+25s |

## Stage dispatcher

| ID | Story | Acceptance |
| --- | --- | --- |
| ST1 | As a dispatcher, I am alerted when auto channels fail | `mobility.stage.dispatch_needed` notification |
| ST2 | As a dispatcher, I manually trigger dispatch | `POST …/stations/{id}/dispatch` |

## Security

| ID | Story | Acceptance |
| --- | --- | --- |
| SEC1 | As a passenger, I share a 6-digit PIN so only my driver starts the trip | `TripBoardingPin` hashed; verify endpoint |
| SEC2 | As ops, I audit channel attempts per offer | `ChannelDispatchAttempt` rows |
