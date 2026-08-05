# National Mobility Registry Deployment and Administration

## Deployment

1. Generate an independent 32-byte AES key and base64 encode it.
2. Set `MOBILITY_DOCUMENT_KEYS_JSON`, for example
   `{"2026-v1":"<base64 key>"}`.
3. Set `MOBILITY_ACTIVE_DOCUMENT_KEY_VERSION=2026-v1`.
4. Generate and set an independent HMAC secret of at least 32 characters as
   `MOBILITY_PII_INDEX_KEY`.
5. Configure a fail-closed malware scanner implementing `DocumentScanner` as
   `MOBILITY_DOCUMENT_SCANNER`.
6. Configure authority adapter class paths only for approved integrations in
   `MOBILITY_VERIFICATION_ADAPTERS_JSON`.
7. Apply migrations, then deploy web, worker and beat processes.
8. Verify `/startupz`, `/readyz`, `/metrics`, the daily expiry task and the
   notification publisher.

Keys must come from the deployment secret manager, not source control or image
layers. PostgreSQL backups contain ciphertext but remain encrypted and
access-controlled under the platform backup policy.

## Key rotation

Add the new version to the key JSON, deploy it to every web/worker instance, then
change the active version. Retain old versions while data references them.
Rotation is complete only after a controlled re-encryption job and restore test
prove every document can be decrypted under the retained keyring. Removing a
referenced key is a production incident.

## Administration

The migration creates Customer, Driver, Station Manager, Fleet Owner, Regional
Officer, Compliance Officer, Operations Officer and Super Administrator role
definitions. Assign staff through `PlatformPrincipal`; regional staff must have
an explicit `attributes.regions` list. Keep maker and checker identities
separate.

Applications and encrypted profiles are not editable in Django Admin. Reviews,
approvals, rejections and suspensions must use Registry commands so workflow,
audit, event and projection records remain consistent.

Policy changes are versioned: create a new effective policy rather than editing
historical requirements. Validate new requirements against active participants
before activation.

## Critical compliance finding

1. Open the compliance queue and identify the application and finding.
2. Confirm whether the operational projection is already suspended.
3. If still eligible, invoke the suspension command with evidence-based reason.
4. Preserve documents and audit history; do not alter encrypted rows directly.
5. Escalate blacklisting decisions to the authorized compliance officer.
6. Verify dispatch no longer returns the participant.

## Verification backlog

1. Segment the queue by region, type and stage.
2. Check reviewer availability and authority-adapter health.
3. Reassign work only to principals permitted for the affected regions.
4. Never bypass stages or bulk-approve to clear backlog.
5. Scale verification workers and document scanning capacity if arrival rate
   exceeds review capacity.

## Notification backlog

1. Check Celery worker and broker health.
2. Run `mobility_registry.publish_notifications` with a bounded batch.
3. Inspect the TAIFA event outbox and downstream notification consumer.
4. Re-run safely; notification deduplication keys prevent duplicate creation.
5. Do not mark records published without an event-outbox record.

## Expiry incident

The daily `mobility_registry.monitor_expiry` task creates 30/14/7/1-day and
expiry notifications. Required expired documents create critical findings and
suspend Registry and operational projections atomically. If the task was
unavailable, restore Celery Beat, run it manually once, verify metrics, and
sample dispatch results for suspended participants.

## Backup and recovery checks

Registry restoration is successful only when:

- application/profile/document row counts reconcile;
- workflow transitions and audit records remain append-only;
- a sampled encrypted document decrypts with authenticated context;
- blind-index search returns the expected masked record;
- approved projections reference the restored Registry UUIDs; and
- an expired participant remains excluded from dispatch.
