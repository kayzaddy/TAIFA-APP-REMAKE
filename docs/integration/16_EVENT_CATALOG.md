# 16 — Event Catalog (Master Index)

---

## Executive summary

**TIP master event catalog**—indexes all `taifa.*` buses; schema registry authority; does not replace domain event definitions.

---

## TIP platform events

| Event | When |
| --- | --- |
| `tip.partner.registered` | New partner |
| `tip.subscription.created` | API product subscribed |
| `tip.api.key.issued` | Credential created |
| `tip.certificate.rotated` | mTLS cert |
| `tip.webhook.delivered` | Outbound success |
| `tip.webhook.failed` | DLQ |
| `tip.flow.completed` | Integration flow |
| `tip.adapter.health.degraded` | ESB alert |
| `tip.policy.updated` | Rate/policy change |

---

## Domain indexes (link only)

| Domain | Catalog |
| --- | --- |
| Payments | [payments/15_EVENT_CATALOG.md](../payments/15_EVENT_CATALOG.md) |
| TNPI phases | orchestration, fraud-risk, developer-platform packs |
| Mobility | [mobility/09_EVENT_CATALOG.md](../mobility/09_EVENT_CATALOG.md) |
| Transport | [transport/08_EVENT_CATALOG.md](../transport/08_EVENT_CATALOG.md) |
| Government | [government/08_EVENT_CATALOG.md](../government/08_EVENT_CATALOG.md) |

---

## CloudEvents envelope

Mandatory `id`, `source`, `type`, `time`, `datacontenttype`, `data`, `taifaenvironment`.

---

## Implementation strategy

Schema registry in EventBridge + Git.

---

## Cross-references

[04_EVENT_BUS.md](04_EVENT_BUS.md)
