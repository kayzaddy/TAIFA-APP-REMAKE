# Taifa AI OS

Intelligence as shared platform infrastructure. Domains consume AI through APIs — they do not build private AI stacks.

## Principles

- AI **augments** humans; critical financial/regulatory actions need human approval workflows
- Every decision includes **confidence**, **reasoning**, **evidence**, and an **audit trail**
- Never bypass Security, Payments, Identity, Ledger, or Compliance
- Outputs are **advisory** unless an approved enterprise workflow completes

## Architecture

```text
Domains (Mobility, Finance, Health, …)
        │
        ▼
  /api/v1/ai-os/   Inference Gateway
        │
   ┌────┼────┬──────────┬────────────┐
   ▼    ▼    ▼          ▼            ▼
 Caps Agents Knowledge Automation Responsible AI
   │
   ▼
 Model Registry · Feature Store · Vector Store · Metrics
```

## Capabilities (shared)

NLP · Vision · OCR · Speech (ASR/TTS) · Recommendations · Fraud · Risk · Forecasting · Optimization · Classification · Semantic Search · Knowledge Graph · Embeddings · Translation · Document Intelligence — plus domain capabilities (AML, ETA, crop planning, …).

## Agents

| Agent | Domain |
| --- | --- |
| financial_agent | enterprise / payments advisory |
| mobility_agent | mobility |
| healthcare_agent | healthcare (non-diagnostic) |
| government_agent | government |
| commerce_agent | commerce |
| agriculture_agent | agriculture |
| education_agent | education |
| enterprise_ops_agent | enterprise |
| developer_agent | engineering |
| citizen_assistant | citizens |

## Key APIs

| Method | Path |
| --- | --- |
| GET | `/api/v1/ai-os/command-center` |
| GET | `/api/v1/ai-os/capabilities` |
| POST | `/api/v1/ai-os/infer/{capability}` |
| GET | `/api/v1/ai-os/agents` |
| POST | `/api/v1/ai-os/agents/{code}/run` |
| POST | `/api/v1/ai-os/knowledge/search` |
| POST | `/api/v1/ai-os/automations/{rule}/run` |
| POST | `/api/v1/ai-os/decisions/{id}/approve` |
| GET | `/api/v1/ai-os/registry` |
| POST | `/api/v1/ai-os/features` |

Decision envelope always includes: `decision_id`, `confidence_e4`, `reasoning_summary`, `evidence`, `requires_human_approval`, `audit_id`.

## Data platform

- **Model Registry** — versions, deployment mode (cloud/onprem/hybrid), rollback target
- **Dataset Registry** — training/eval sets with PII class
- **Feature Store** — entity-scoped feature snapshots
- **Vector Store** — portable JSON embeddings (swap for dedicated vector DB later)
- **Knowledge documents** — policies/regulations/manuals with citations

## Responsible AI

- Prompt injection blocking + safety events
- PII redaction / deny policies
- Forbidden action denylist (ledger/identity bypass)
- Human approval via `enterprise.workflow` for fraud/AML/credit/etc.
- Low-confidence hallucination flags

## Super App

Flutter **AI Command Center** at `/ai-ops`. Citizen chat remains `/ai` (can call `citizen_assistant`).

## Seed

```bash
cd apps/backend
.\.venv\Scripts\python.exe manage.py seed_ai_os
```

Live model backends: set `TAIFA_AI_OS_ADAPTERS_JSON` to map model codes → adapter classes.

## Docs

- [`AI_OS_ARCHITECTURE.md`](AI_OS_ARCHITECTURE.md)
- [`AI_OS_RESPONSIBLE.md`](AI_OS_RESPONSIBLE.md)
- [`AI_OS_DEPLOYMENT.md`](AI_OS_DEPLOYMENT.md)
