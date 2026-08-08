# 13 — Implementation Guide

---

## Executive summary

Phase 6 stages RC-0–RC-7: ingest, matcher, exceptions, close, reports, gate.

---

## Dependencies

Orchestration read API · Settlement export v1 · PSP file formats · Phase 5 payout refs.

---

## Stages

| Stage | Weeks | Deliverable |
| --- | --- | --- |
| RC-0 | 2 | Schema, OpenAPI, S3 landing |
| RC-1 | 4 | M-Pesa payment file matcher 1:1 |
| RC-2 | 3 | Payout recon |
| RC-3 | 3 | Settlement batch recon |
| RC-4 | 4 | Exception workflow + maker-checker |
| RC-5 | 3 | Daily close + reports |
| RC-6 | 2 | Real-time payment recon (optional stream) |
| RC-7 | 2 | Gate + Phase 7 handoff spec |

---

## Implementation strategy

Flag `tnpi.reconciliation`; parallel manual Excel compare in pilot.

---

## Operational model

Runbook: late file, re-run job, reopen exception.

---

## Future expansion

Multi-provider parallel jobs.

---

## Cross-references

[15_BACKLOG.md](15_BACKLOG.md) · [PHASE6_GATE_PACKAGE.md](PHASE6_GATE_PACKAGE.md)
