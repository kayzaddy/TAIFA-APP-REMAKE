# 15 — Acceptance Criteria

---

## Executive summary

Staging acceptance for Developer Platform before production launch and Phase 9 Transport Payments Platform.

---

## Registration & apps (AC-D1–D4)

| ID | Criterion |
| --- | --- |
| AC-D1 | Developer registers and verifies email |
| AC-D2 | Organization + application created |
| AC-D3 | Sandbox API key works on `/v1/payments` proxy |
| AC-D4 | Production key blocked until application approved |

---

## Gateway & sandbox (AC-D5–D8)

| ID | Criterion |
| --- | --- |
| AC-D5 | Rate limit returns 429 with standard error |
| AC-D6 | Sandbox cannot hit production upstream |
| AC-D7 | Error simulation returns documented codes |
| AC-D8 | Request ID echoed in all responses |

---

## Webhooks (AC-D9–D11)

| ID | Criterion |
| --- | --- |
| AC-D9 | Test webhook delivers signed payload |
| AC-D10 | Retry on 503 then success logged |
| AC-D11 | DLQ after max retries + alert |

---

## SDK & docs (AC-D12–D14)

| ID | Criterion |
| --- | --- |
| AC-D12 | Node sample completes sandbox payment |
| AC-D13 | Flutter sample completes sandbox payment |
| AC-D14 | OpenAPI portal matches gateway routes |

---

## Certification (AC-D15–D16)

| ID | Criterion |
| --- | --- |
| AC-D15 | Certification checklist submitted and reviewed |
| AC-D16 | `developer.certified` event emitted |

---

## Non-functional (AC-N1–N3)

| ID | Criterion |
| --- | --- |
| AC-N1 | Gateway p99 &lt; 100 ms overhead at 200 RPS staging |
| AC-N2 | No payment logic in developer platform services (scan) |
| AC-N3 | All key operations in audit log |

---

## Exit Phase 9

[PHASE8_GATE_PACKAGE.md](PHASE8_GATE_PACKAGE.md) §6.

---

## Cross-references

[16_DEFINITION_OF_DONE.md](16_DEFINITION_OF_DONE.md)
