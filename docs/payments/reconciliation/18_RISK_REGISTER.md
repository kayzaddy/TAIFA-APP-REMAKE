# 18 — Risk Register

| ID | Risk | Pri | Mitigation |
| --- | --- | --- | --- |
| RC-01 | False auto-match | P1 | Confidence thresholds + sample audit |
| RC-02 | Wrong adjustment posted | P1 | Maker-checker + limited API |
| RC-03 | Provider format change | P1 | Versioned parsers + alerts |
| RC-04 | Close with open exceptions | P1 | Pre-close gates |
| RC-05 | Data leak in reports | P2 | Redaction + RBAC |
| RC-06 | Job overload | P2 | Scale workers + backpressure |

---

## Cross-references

[PHASE6_GATE_PACKAGE.md](PHASE6_GATE_PACKAGE.md)
