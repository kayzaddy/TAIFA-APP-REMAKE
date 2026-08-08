# 06 — Webhook Platform

---

## Executive summary

Managed **webhook delivery**: registration, HMAC verification, retries, DLQ, delivery logs, event filtering, versioning, replay protection—subscribing to TNPI EventBridge and fan-out to partner HTTPS endpoints.

---

## Business purpose

Reliable async integration without partners polling payment state.

---

## Architecture overview

```mermaid
flowchart TB
  EB[EventBridge tnpi-platform]
  RULE[Subscription rules]
  ENR[Event enricher]
  Q[SQS per endpoint]
  W[Webhook workers Fargate]
  DLQ[DLQ]
  EB --> RULE --> ENR --> Q --> W
  W -->|fail max| DLQ
  W --> PARTNER[Partner HTTPS]
```

---

## Registration model

Per application: URL, secret, event types[], API version, active flag, optional IP allowlist on partner side (documented).

---

## Verification

```
TNPI-Signature: t={timestamp},v1={hmac_sha256_hex}
signed_payload = timestamp + "." + raw_body
```

Reject if timestamp skew &gt; 5 minutes (replay protection).

---

## Retry policy

| Attempt | Delay |
| --- | --- |
| 1 | immediate |
| 2 | 1 min |
| 3 | 5 min |
| 4 | 30 min |
| 5 | 2 h |
| 6 | 24 h |

Then DLQ + `webhook.delivery.failed` alert.

---

## Sequence: delivery

```mermaid
sequenceDiagram
  participant EB as EventBridge
  participant W as Webhook service
  participant P as Partner
  EB->>W: payment.completed
  W->>W: sign payload
  W->>P: POST webhook
  alt 200
    W->>W: log success
  else 5xx
    W->>W: schedule retry
  end
```

---

## Developer journey

Portal → Webhooks → Add endpoint → Select events → Send test → View delivery log.

---

## API (admin)

See [08_API_SPECIFICATION.md](08_API_SPECIFICATION.md) — `/v1/webhooks/*`.

---

## ER

```mermaid
erDiagram
  APPLICATION ||--o{ WEBHOOK : owns
  WEBHOOK ||--o{ WEBHOOK_DELIVERY : logs
```

---

## Security

Secrets in Secrets Manager; rotate via portal; TLS 1.2+ only.

---

## AWS

SQS + Lambda/Fargate; idempotency key `event_id` in partner docs.

---

## Implementation strategy

DP-3: core delivery; DP-4: portal UI + replay tool (signed, audit).

---

## Future expansion

Partner mTLS client auth to Taifa egress IPs.

---

## Cross-references

[07_API_SECURITY.md](07_API_SECURITY.md) · [09_EVENT_CATALOG.md](09_EVENT_CATALOG.md)
