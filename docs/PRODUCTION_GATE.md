# TAIFA Production Gate — Real-Funds Certification

**Date:** 2026-07-16  
**Scope:** Eliminate P0 blockers so the platform may hold real customer funds in a controlled pilot.  
**Standard:** Bank of Tanzania / external financial audit / security audit readiness — not feature completeness.

This phase adds **no** customer-facing product features (QR, lending, savings, merchant UX).

---

## Certification summary

| Blocker | Status |
|---------|--------|
| P0-1 Demo Funding | **PASS** |
| P0-2 Admin Protection | **PASS** |
| P0-3 Webhook Security | **PASS** |
| P0-4 Payment Routing | **PASS** |
| P0-5 Risk Defaults | **PASS** |
| P0-6 Settlement Reconciliation | **PASS** |

### Production Gate

**PASSED**

Platform is ready for a **controlled pilot with real customer funds**, provided operators deploy with production env (see checklist below) and run daily ledger + provider settlement reconciliation.

Automated evidence: `python manage.py test payments` (includes `payments.tests.test_p0_production_gates`).

---

## P0-1 — Demo wallet minting

| Lens | Finding |
|------|---------|
| Business | Demo mint creates unfunded liability and false balances. |
| Security | Anyone hitting register/demo paths could inflate wallets. |
| Accounting | Credits without settlement violate conservation. |

**Controls**

- `ALLOW_DEMO_WALLET_FUNDING` / `TAIFA_ALLOW_DEMO_WALLET_FUNDING` defaults to `DEBUG` only.
- Device register opens a zero wallet when funding is disallowed.
- `TAIFA_ALLOW_DEMO_STK` gated; Django system check `payments.E001`/`E002` refuse demo flags when `DEBUG=false`.
- CI runs `manage.py check` under production-shaped env (demo flags off + webhook secret + finite risk).

---

## P0-2 — Financial Django Admin immutability

| Lens | Finding |
|------|---------|
| Business | Staff edits bypass approval and create untraceable “fixes”. |
| Security | Privilege escalation via Admin. |
| Accounting | Direct mutation breaks immutability and audit. |

**Controls**

- `FinancialReadOnlyAdmin` on Transaction, Ledger*, Posting, Webhook*, DomainEvent, AuditRecord, Settlement*, ReconciliationException.
- Corrections only via Payment Engine / Orchestrator compensating journals.

---

## P0-3 — Webhook security

| Lens | Finding |
|------|---------|
| Business | Forged callbacks settle false credits/debits. |
| Security | Replay, forgery, unsigned callbacks. |
| Accounting | Fake settles create orphan or unbalanced liability. |

**Controls** (`payments/webhook_auth.py`)

- Shared secret header and/or HMAC-SHA256 (`X-TAIFA-Webhook-Timestamp` + `X-TAIFA-Webhook-Signature`).
- Timestamp skew (`MPESA_WEBHOOK_MAX_SKEW_SECONDS`).
- Replay guard (`WebhookReplayGuard`).
- Optional IP allow-list (`MPESA_WEBHOOK_ALLOWED_IPS`).
- Fail-closed in production (`MPESA_WEBHOOK_FAIL_CLOSED`, `MPESA_WEBHOOK_REQUIRE_HMAC`).
- System check `payments.E004` requires `MPESA_WEBHOOK_SHARED_SECRET` when not DEBUG.

Unsigned callbacks must not change money.

---

## P0-4 — Money flow consistency

| Lens | Finding |
|------|---------|
| Business | Bypass paths settle without risk/audit. |
| Security | Direct engine/webhook shortcuts. |
| Accounting | Settles without journal or events. |

**Canonical path**

API → Auth → Risk → Orchestrator → Engine/Journal → Ledger → Settlement → Events → Notifications → Audit

**Controls**

- Money APIs go through `PaymentOrchestrator`.
- M-Pesa STK callbacks settle via `orchestrator.settle_mpesa_stk_callback` (audit + domain events).
- Engine `_settle` locks rows, posts journal, refreshes caller instance (no stale `processing` after sync accept).
- No demo mint in production; no Admin mutation of financial rows.

---

## P0-5 — Risk defaults

| Lens | Finding |
|------|---------|
| Business | Unlimited defaults enable runaway exposure. |
| Security | Velocity / sanctions gaps. |
| Accounting | Unbounded debits/credits amplify recon breaks. |

**Controls**

- Production defaults: finite per-txn, daily debit, daily credit, review threshold.
- Velocity window + max txns; sanctions owner list.
- `RISK_ALLOW_UNLIMITED` required to permit `0` limits in production (`payments.E005`/`E006`).
- `REQUIRE_DEVICE_BINDING` when not DEBUG.

---

## P0-6 — Provider settlement reconciliation

| Lens | Finding |
|------|---------|
| Business | Unmatched provider files hide lost funds / duplicate payouts. |
| Security | Unexpected settlements may indicate fraud. |
| Accounting | Ledger must match rail settlement files. |

**Controls**

- Models: `SettlementBatch`, `SettlementLine`, `ReconciliationException`.
- `ingest_settlement_csv` + `reconcile_batch` (amount/currency/unknown/duplicate/late/missing).
- Command: `python manage.py ingest_settlement_csv <file> --reconcile [--full-day]`.
- Metrics: `taifa_provider_reconciliation_exceptions`, `taifa_provider_reconciliation_matched_total`.
- Alert: `TaifaProviderSettlementExceptions` in `deploy/observability/alert_rules.yml`.

---

## Operational production checklist

Before enabling real funds:

1. `DJANGO_DEBUG=false`, strong `DJANGO_SECRET_KEY`, locked hosts/CORS.
2. `TAIFA_ALLOW_DEMO_WALLET_FUNDING=false`, `TAIFA_ALLOW_DEMO_STK=false`, `TAIFA_WITHDRAWAL_AUTO_APPROVE=false`.
3. `MPESA_WEBHOOK_SHARED_SECRET` set; HMAC + IP allow-list as edge supports.
4. Finite `RISK_*` limits; do not set `RISK_ALLOW_UNLIMITED` without written approval.
5. Postgres + Redis HA/backups; `/healthz` + `/readyz`; Prometheus scrape + Alertmanager.
6. Daily: `reconcile_ledger` and provider CSV ingest `--reconcile`.
7. `python manage.py check` must exit 0 on the production image.

---

## Related docs

- Architecture: [`CORE_BANKING_ARCHITECTURE.md`](CORE_BANKING_ARCHITECTURE.md), [`PAYMENT_ENGINE.md`](PAYMENT_ENGINE.md)
- Threat model: [`SECURITY.md`](SECURITY.md)
- Ops: [`DEPLOYMENT.md`](DEPLOYMENT.md), [`OBSERVABILITY.md`](OBSERVABILITY.md)
