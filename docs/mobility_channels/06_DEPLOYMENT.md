# Taifa Mobility Hybrid Dispatch — Deployment

## Local development

```bash
cd apps/backend
.venv\Scripts\python.exe manage.py migrate
.venv\Scripts\python.exe manage.py seed_mobility
.venv\Scripts\python.exe manage.py seed_hybrid_dispatch
.venv\Scripts\python.exe manage.py test mobility_channels -v 1
.venv\Scripts\python.exe manage.py runserver 127.0.0.1:8000
```

## Celery (IVR fallback)

Task: `mobility_channels.ivr_fallback` — scheduled 25s after SMS/push offer.

Ensure Celery worker is running with the same broker as the main app.

## Telco configuration

1. Point SMS inbound URL → `https://{host}/api/v1/mobility-channels/webhooks/sms/inbound`
2. USSD callback → `…/webhooks/ussd`
3. IVR DTMF POST → `…/webhooks/ivr/dtmf`

Configure Africa's Talking / Twilio / local Tanzanian aggregator credentials in `integrations.notifications`.

## Monitoring

Prometheus counters (`mobility_channels.metrics`):

- `taifa_mobility_channel_offers_sent_total{channel}`
- `taifa_mobility_sms_inbound_total`
- `taifa_mobility_ussd_sessions_total`
- `taifa_mobility_ivr_fallbacks_total`

## Production checklist

- [ ] Webhook IP allow-list on ALB/nginx
- [ ] Celery workers + beat (if using periodic sweeps)
- [ ] Redis for USSD session cache (future)
- [ ] CloudWatch alerts on `ivr_fallbacks` spike
- [ ] Stage dispatcher training on manual dispatch API
