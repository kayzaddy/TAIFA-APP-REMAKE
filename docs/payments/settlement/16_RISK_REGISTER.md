# 16 — Risk Register

| ID | Risk | Pri | Mitigation |
| --- | --- | --- | --- |
| ST-01 | Double settlement per payment | P1 | Unique payment_id constraint |
| ST-02 | Incorrect split math | P1 | Property tests + maker-checker |
| ST-03 | Payout to wrong account | P1 | Verify settlement account API |
| ST-04 | Batch partial failure | P2 | Retry + exception queue |
| ST-05 | Treasury liquidity | P2 | Prefunding monitoring |
| ST-06 | Regulatory reporting gap | P2 | Compliance review ST-5 |

---

## Cross-references

[PHASE5_GATE_PACKAGE.md](PHASE5_GATE_PACKAGE.md)
