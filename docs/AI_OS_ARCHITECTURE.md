# AI OS Architecture

## Role

Taifa AI OS is the **intelligence operating layer** for Tanzania’s digital ecosystem. It sits beside — never inside — Payments, Identity, and the Ledger.

## Bounded contexts

| Context | Owns | Does not own |
| --- | --- | --- |
| Inference gateway | Decision envelopes, metrics | Journal posts |
| Agents | Domain orchestration + citations | Dispatch FSM / settlement |
| Knowledge | Indexed docs + retrieval | Authority legal SoT |
| Automation | Drafts / routing suggestions | Irreversible money moves |
| Responsible AI | Safety filters, approval flags | Risk engine enforcement |

## Inference contract

Every successful `infer` returns:

1. Result payload  
2. `confidence_e4`  
3. `reasoning_summary`  
4. `evidence[]`  
5. `audit_id` / `decision_id`  
6. Approval fields when required  

## Multimodal

Adapters declare modality (`text`, `vision`, `speech`, `tabular`, `multimodal`). Payloads may include text, document hints, GPS context, and structured enterprise features from the Feature Store.

## Evolution

| Horizon | Change |
| --- | --- |
| Near | Swap StubInferenceAdapter for cloud/on-prem LLM/CV backends |
| Mid | Dedicated vector DB + GPU autoscaling |
| Long | Continuous eval pipelines + drift monitors wired to command center |

Ecosystem `invoke_ai` delegates to AI OS so older clients inherit the same governance envelope.
