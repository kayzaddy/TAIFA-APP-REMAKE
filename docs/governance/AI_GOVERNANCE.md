# AI Governance

AI is a shared platform capability (`ai_os`). Domains consume it; they do not ship private model stacks for core decisions.

## Controls

| Control | Mechanism |
| --- | --- |
| Model registry | `ModelRegistryEntry` |
| Capability registry | `CapabilityDefinition` |
| Decision audit | `AiDecision` envelope (confidence, reasoning, evidence) |
| Human approval | `requires_human_approval` + enterprise workflow |
| Safety | Injection/PII filters, `SafetyEvent` |
| Knowledge citations | Knowledge search with citations |
| Prompt/versioning | Adapter + model_version on decisions; expand Prompt Registry as live LLMs land |
| Eval / drift | Command center metrics; eval datasets in registry |
| Never | Mutate ledger / bypass identity |

Authoritative: [`../AI_OS.md`](../AI_OS.md), [`../AI_OS_RESPONSIBLE.md`](../AI_OS_RESPONSIBLE.md).
