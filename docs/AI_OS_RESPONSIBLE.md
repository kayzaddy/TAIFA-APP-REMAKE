# Responsible AI

## Human oversight

Capabilities with `requires_human_approval=true` (fraud, AML, credit, prescription support, …) create a pending `AiDecision` and optionally start an `enterprise.workflow` instance. Operators approve via:

`POST /api/v1/ai-os/decisions/{id}/approve` with `{"approved": true|false}`.

**Approval never posts payments.** Downstream systems must read the decision and act through Payments/Registry APIs under normal controls.

## Safety controls

| Control | Behavior |
| --- | --- |
| Prompt injection | Block + `SafetyEvent(kind=injection)` |
| Forbidden actions | Block explicit ledger/identity bypass requests |
| PII | Redact (default) or deny per capability policy |
| Low confidence | `SafetyEvent(kind=hallucination)` when confidence_e4 &lt; 4000 |
| Healthcare | Non-diagnostic disclaimers in clinical assists |

## Explainability & audit

All inferences persist on `AiDecision` with request (redacted), result, reasoning, evidence, model version, latency, and token estimate.

## Bias & evaluation

Dataset registry tracks eval sets (`payments-fraud-eval`, …). Command center surfaces low-confidence rates and error counts for drift investigation. Live bias monitors plug into the same `SafetyEvent` stream.
