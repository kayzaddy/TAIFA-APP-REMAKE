# 16 — Checklists and templates

**Owner:** Engineering Council · **Use:** Copy into PRs, gates, incidents

---

## Pull request template

```markdown
## Summary
- 

## Ticket / ADR
- 

## Type
- [ ] Feature  [ ] Fix  [ ] Docs  [ ] Infra

## TEOS
- [ ] Tests added/updated
- [ ] No secrets in diff
- [ ] Observability (logs/metrics) if new path
- [ ] Authz checked server-side
- [ ] OpenAPI updated if API change

## Screenshots / logs (if UI)
```

---

## Code review

- [ ] Correctness and edge cases  
- [ ] Tests meaningful  
- [ ] Naming and style per [04_CODING_STANDARDS.md](04_CODING_STANDARDS.md)  
- [ ] No duplicate platform capability  
- [ ] Migrations reversible or documented  
- [ ] Performance / N+1 considered

---

## Engineering Gate Review (EGR) {#egr}

| # | Criterion | Pass |
| --- | --- | --- |
| 1 | Aligns with EA / no duplication | ☐ |
| 2 | ADR if structural | ☐ |
| 3 | CI green | ☐ |
| 4 | Test plan executed | ☐ |
| 5 | Observability | ☐ |
| 6 | Rollback documented | ☐ |
| 7 | Conditions tracked (if any) | ☐ |

**Outcome:** PASS / PASS WITH CONDITIONS / FAIL  
**Reviewer:** __________ **Date:** __________

---

## Product Acceptance Review (PAR)

- [ ] Meets acceptance criteria in ticket/PRD slice  
- [ ] UX reviewed (if applicable)  
- [ ] Known gaps documented  
- [ ] Not production pilot unless explicitly scoped

---

## Security gate (G-SEC)

- [ ] Threat model (if required)  
- [ ] SAST/secret scan clean  
- [ ] RBAC tests  
- [ ] No PAN/secrets in logs  
- [ ] Pen test items closed (if GA payments)

---

## QA gate (G-QA)

- [ ] Regression pass  
- [ ] No open Sev1/2  
- [ ] Coverage on changed code  
- [ ] Accessibility spot-check (if UI)

---

## Release

- [ ] Version/changelog  
- [ ] EGR + PAR + G-SEC + G-QA as required  
- [ ] Feature flags configured  
- [ ] Runbook updated  
- [ ] On-call notified

---

## Threat model (lite)

| Threat | Mitigation | Owner |
| --- | --- | --- |
| Spoofing | | |
| Tampering | | |
| Repudiation | | |
| Info disclosure | | |
| DoS | | |
| Elevation | | |

---

## Post-incident review (PIR)

- **Incident ID:**  
- **Duration / impact:**  
- **Timeline:**  
- **Root cause:**  
- **Actions (owner, due):**  
- **Lessons (blameless):**

---

## Cross-references

[10_RELEASE_MANAGEMENT.md](10_RELEASE_MANAGEMENT.md) · [19_DECISION_RECORDS.md](19_DECISION_RECORDS.md)
