# 8. Operations Handbook

## Metrics

- `taifa_tap_started_total{channel}`
- `taifa_tap_auth_total{method}`
- `taifa_tap_succeeded_total{channel}`
- `taifa_tap_failed_total{reason}`

## KPIs

Tap success rate · auth latency · funding mix · failure reasons · DAU wallet NFC

## Incidents

| Symptom | Action |
| --- | --- |
| Auth required loop | Check session auth_completed |
| Insufficient funds | Top-up; do not retry same idempotency blindly |
| Duplicate fear | Idempotency-Key + intent status |
