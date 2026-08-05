# TAIFA Security Model

Money and identity are the crown jewels. This document is the threat model and
the checklist of controls that are **implemented today** vs. **planned**, so a
reviewer can tell real hardening from aspiration.

## Trust boundaries

```
[Mobile app]  ──TLS──▶  [Edge / reverse proxy]  ──▶  [Django payment service]  ──▶  [Postgres]
     │                                                      │
  device token                                          [Celery]  ──▶  [M-Pesa Daraja]
                                                            ▲
                          [M-Pesa]  ──webhook──▶  [Django] ─┘
```

- The mobile client is **untrusted**. Everything authoritative (balances,
  ledger, transitions) lives server-side.
- The provider webhook is **semi-trusted**: it cannot present a device token, so
  it is matched to a pending transaction by `provider_ref` and is idempotent.

## Controls implemented

| Area | Control | Where |
|------|---------|-------|
| AuthN | Device-bound bearer token; server stores only the SHA-256, plaintext returned once | `payments/auth.py` |
| AuthN | Token bound to `X-Device-Id`; a leaked token is useless without the device header | `payments/auth.py` |
| AuthZ | Every wallet read/write is scoped to the authenticated device's `owner` | `payments/views.py`, `engine.py` |
| Integrity | Double-entry ledger; entries must net to zero per currency | `payments/ledger.py` |
| Integrity | Ledger tables append-only in the ORM **and** via a Postgres trigger | `models.py`, `migrations/0002` |
| Exactly-once | `Idempotency-Key` required on money writes; replays return the original txn | `engine.py` |
| Money safety | Integer minor units end-to-end; no floats in value math | `money.py` / `money.dart` |
| Abuse | DRF throttling: anon, `device_register`, `money_write` scopes (env-tunable) | `config/settings.py` |
| Transport | HSTS, SSL redirect, secure cookies, `nosniff`, `X-Frame-Options: DENY` when `DEBUG=false` | `config/settings.py` |
| CORS | Locked by default in prod; explicit allow-list via env | `config/settings.py` |
| Secrets | 12-factor env; `.env` git-ignored; only token hashes stored | `.env.example` |
| Traceability | Per-request `X-Request-ID` correlated across logs (and Sentry) | `config/middleware.py` |
| Least data | Webhook payloads persisted immutably; PII not sent to Sentry (`send_default_pii=False`) | `settings.py`, `webhooks.py` |
| Webhook trust | Shared secret and/or HMAC-SHA256, timestamp skew, replay guard, IP allow-list; fail-closed in production | `payments/webhook_auth.py` |
| Demo mint | Demo wallet funding / demo STK refused by system checks when `DEBUG=false` | `payments/production_gates.py` |
| Admin | Financial models read-only in Django Admin | `payments/admin.py` |
| Risk | Finite production defaults; unlimited requires explicit `RISK_ALLOW_UNLIMITED` | `payments/risk.py`, settings |

## Top risks & mitigations

1. **Stolen device token** → bound to `X-Device-Id`; server can revoke a single
   `Device` row; short-lived rotation is a planned follow-up.
2. **Replay / double-spend** → idempotency keys + append-only ledger + balanced
   entries inside DB transactions; webhook replay fingerprints.
3. **Forged webhook** → matched to an existing pending txn only; production
   requires `MPESA_WEBHOOK_SHARED_SECRET`, optional HMAC
   (`X-TAIFA-Webhook-Timestamp` / `X-TAIFA-Webhook-Signature`), IP allow-list
   (`MPESA_WEBHOOK_ALLOWED_IPS`), and structural STK checks
   (`payments/webhook_auth.py`). Unsigned callbacks must not change money.
4. **Enumeration / brute force** → throttling on registration and money writes;
   generic error messages; UUID primary keys (non-sequential).
5. **Privilege escalation across wallets** → owner scoping on every query; a
   device literally cannot address another owner's transaction. Admin cannot
   mutate financial rows.
6. **Demo / unlimited risk in prod** → Django system checks `payments.E001`–
   `E006` refuse demo funding, demo STK, auto-approve withdrawals, missing
   webhook secret, and unlimited risk without approval.

Certification evidence: [`PRODUCTION_GATE.md`](PRODUCTION_GATE.md).

## Planned (gated on external resources / later phases)

- User identity + KYC tiers, step-up MFA and biometric re-auth on high-risk ops.
- Short-lived access tokens + refresh; device attestation (Play Integrity / App
  Attest).
- Secrets in a managed vault (AWS/GCP Secrets Manager) rather than env files.
- WAF / DDoS protection at the edge; field-level encryption for sensitive PII.
- Independent security review + penetration test before public launch.

## Reporting

Security issues should be reported privately to the maintainers, not via public
issues. A `SECURITY.txt` and disclosure policy will accompany the public launch.
