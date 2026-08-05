# TAIFA Mobility Runbooks

## SOS or panic incident

Trigger: `TaifaMobilitySOSOpen`.

1. Acknowledge the incident in the Operations Dashboard immediately.
2. Confirm reporter, trip, latest GPS point, assigned driver/vehicle and trusted
   contact workflow. Do not expose location outside authorized responders.
3. Contact the reporter using the verified channel. If unreachable or the
   incident indicates immediate danger, escalate to the configured local
   emergency authority.
4. Preserve trip events, location history, WebSocket/event logs and audit
   records. Do not edit evidence.
5. Keep the incident open through response and verification.
6. Record responder, actions, external case reference and resolution.
7. Initiate post-incident safety review and required regulator notification.

## Dispatch backlog

Trigger: `TaifaMobilityDispatchBacklog`.

1. Check API, Celery worker and Redis health.
2. Compare searching trips, pending offers and available compliant drivers by
   station.
3. If offers are not being generated, inspect
   `mobility.dispatch_scheduled` and `mobility.expire_dispatch_offers`.
4. If supply is low, alert station managers and use audited positioning
   recommendations. Never bypass driver/vehicle verification.
5. If Redis/WebSockets are impaired, drivers can recover offers via REST.
6. Do not manually assign by editing database rows; use the dispatch service.

## Payment backlog

Trigger: `TaifaMobilityPaymentBacklog`.

1. Separate cash `payment_pending` from electronic payment failures.
2. For electronic payments, inspect the referenced Taifa Payment transaction,
   orchestrator event, ledger posting, provider status and outbox.
3. Retry only through the existing idempotent payment command using the same
   key. Never insert a payment reference or ledger row in Mobility.
4. For cash, run station collection/provider reconciliation in Taifa Payments.
5. Confirm ledger reconciliation before marking operational incidents resolved.

## GPS or WebSocket outage

1. Check Redis Channels, ASGI instances and network error rate.
2. Confirm REST driver location batch ingestion remains available.
3. Mobile clients retain ordered location batches and replay after recovery.
4. Scale/restart ASGI workers using the deployment runbook.
5. Verify customer/driver authorization before restoring subscriptions.
6. Confirm delayed GPS points are not presented as current; use `recorded_at`.

## Station queue inconsistency

1. Quiesce queue joins for the affected station.
2. Export active queue rows and append-only offer/trip events.
3. Rebuild positions ordered by priority, existing position and joined time in
   one transaction.
4. Never assign an unavailable, suspended or non-compliant driver.
5. Re-enable joins and verify the station dashboard.

## Provider or map outage

1. Keep existing trips operational using last accepted route and GPS.
2. Stop accepting routes that cannot be safely priced or navigated.
3. Do not silently substitute distance or fare.
4. Activate the approved secondary provider if configured.
5. Track provider recovery, stale cache age and affected trips.

## Data protection

- National IDs, recipient codes, secrets and raw payment credentials must not
  appear in logs.
- GPS access is limited to trip participants and authorized operations.
- Apply the approved GPS retention/deletion policy; safety holds must be
  documented and time-bounded.
- Export and regulator access requires enterprise RBAC and audit.
