# 10. Operations Manual

## Metrics (Prometheus)

- `taifa_map_intents_created_total{channel}`
- `taifa_map_qr_issued_total{kind}`
- `taifa_map_payments_succeeded_total{channel}`
- `taifa_map_payments_failed_total{channel}`
- `taifa_map_receipts_issued_total`

## Alerts (suggested)

- Spike in `payments_failed`
- Intent expire rate vs create rate
- Capture latency via payments service SLOs (not MAP-local money)

## Incident notes

| Symptom | Check |
| --- | --- |
| Signature invalid | Clock skew / mutated intent fields |
| Insufficient funds | Payer wallet (payments) |
| Merchant not active | `enterprise.Merchant.status` |
| Double charge fear | Idempotency-Key + intent status |

Settlement / refunds: use Payments + Enterprise settlement APIs — never invent MAP payouts.
