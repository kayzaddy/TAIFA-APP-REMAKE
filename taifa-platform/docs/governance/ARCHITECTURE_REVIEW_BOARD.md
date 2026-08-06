# Architecture Review Board (ARB)

**Mandate:** Approve structural changes, service boundaries, anti-duplication, and cross-platform contracts.

---

## Scope

- New entries under `platforms/`, `services/`, `apis/`
- Breaking changes to shared `packages/`
- Monorepo tree changes ([REPOSITORY_TREE.md](../engineering/REPOSITORY_TREE.md))
- PDL entries promoted from squads

---

## Cadence

- Weekly triage; emergency session within 24h for production risk

---

## Inputs

- ADR draft
- Threat model (security-sensitive)
- TIP registration plan (public APIs)

---

## Outputs

- Approved / deferred / rejected with conditions
- PDL entry in [`../../../docs/platform/17_PLATFORM_DECISION_LOG.md`](../../../docs/platform/17_PLATFORM_DECISION_LOG.md)

---

## Cross-references

[REPOSITORY_GOVERNANCE.md](REPOSITORY_GOVERNANCE.md) · [`../../../docs/governance/EA_GOVERNANCE.md`](../../../docs/governance/EA_GOVERNANCE.md)
