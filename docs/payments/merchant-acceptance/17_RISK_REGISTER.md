# 17 — Risk Register

| ID | Risk | Pri | Mitigation |
| --- | --- | --- | --- |
| MAP-01 | Offline double charge on sync | P1 | Idempotency + signed queue |
| MAP-02 | PCI scope creep in MAP API | P1 | Architecture review |
| MAP-03 | QR amount tamper | P1 | Signed payload |
| MAP-04 | Bypass orchestration | P1 | API gateway policy + lint |
| MAP-05 | Scheme cert delay | P2 | Partner SDK early |
| MAP-06 | Device theft | P2 | Remote disable |

---

## Cross-references

[PHASE4_GATE_PACKAGE.md](PHASE4_GATE_PACKAGE.md)
