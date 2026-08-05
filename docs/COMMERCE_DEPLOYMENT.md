# Taifa Commerce — Deployment Guide

## Install

```bash
cd apps/backend
python manage.py migrate mos
python manage.py seed_mos   # optional demo
```

Ensure `mos.apps.MosConfig` is in `INSTALLED_APPS` and `/api/v1/mos/` is mounted.

## Dependencies

- `enterprise` (Merchant + capture)  
- `payments` (ledger)  
- `winga` (optional publish; run `seed_winga` first)  

## Observability

Prometheus counters: `taifa_mos_*` (orders, stock movements, Winga publishes).

## Rollback

MOS tables are additive. Disable route mount if needed; do not drop ledger data.
