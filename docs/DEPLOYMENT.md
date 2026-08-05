# TAIFA Deployment Runbook

How to build, ship and operate the payment service. Everything here is runnable;
the only things this repo cannot do for you are the parts that need **your**
accounts (a cloud host, a domain + TLS cert, and production M-Pesa Daraja
credentials) — those steps are called out explicitly.

## Environments

| Env | DB | Debug | Notes |
|-----|----|-------|-------|
| dev | SQLite (fallback) | true | zero infra; `manage.py runserver` |
| CI | SQLite | n/a | GitHub Actions runs tests + schema validation |
| staging/prod | Postgres | false | `docker-compose.prod.yml` behind nginx |

## CI (already wired)

`.github/workflows/ci.yml` runs on every push/PR:

- **backend** — `manage.py check`, `manage.py test`, and
  `spectacular --fail-on-warn` (fails the build if the API contract regresses).
- **mobile** — `flutter analyze` + `flutter test`.

## Build & run production-shaped locally

```bash
cd apps/backend
cp .env.example .env         # then edit: strong DJANGO_SECRET_KEY, DJANGO_DEBUG=false,
                             # POSTGRES_PASSWORD, DJANGO_ALLOWED_HOSTS, CORS_* ...
docker compose -f docker-compose.prod.yml --env-file .env up -d --build
```

Boot order is enforced: `db` (healthcheck) → `release` (migrate + collectstatic)
→ `web` (gunicorn, `/readyz` healthcheck) + `worker` (Celery) → `nginx` (:80).

Verify:

```bash
curl localhost/healthz   # ok
curl localhost/readyz    # ready
open  localhost/api/docs # Swagger UI
```

## Release procedure

1. Merge to `main` → CI green.
2. Build & push the image to your registry (tag with the git SHA).
3. Run the **release** step (migrate + collectstatic) — it is idempotent and
   gates the web rollout in `docker-compose.prod.yml`.
4. Roll `web`/`worker`. `/readyz` must pass before traffic shifts.
5. Smoke test: register a device → `GET /wallet` → a small `POST /transfers`.

### Rollback
Ledger and transactions are append-only, so **never** roll a migration back over
posted money. Roll the *application image* back to the previous SHA; forward-fix
data with compensating transactions, not deletes.

## Cloud hosting (needs your account)

The compose file maps cleanly onto any container host. Pick one:

- **Single VM** (fastest): a VM + Docker; point DNS at it; add TLS via a managed
  LB or swap nginx for Caddy/Traefik with automatic Let's Encrypt.
- **Managed containers**: Fly.io / Render / Railway / AWS ECS / GCP Cloud Run for
  `web` + `worker`, managed Postgres + Redis. Set the same env vars.
- **Kubernetes**: `web` Deployment (HPA on CPU), `worker` Deployment, managed
  Postgres/Redis, Ingress with cert-manager. `/healthz` = liveness, `/readyz` =
  readiness.

**You must provide:** the host/cluster, a managed Postgres + Redis, DNS + TLS
certificate, and secrets (`DJANGO_SECRET_KEY`, DB creds, `SENTRY_DSN`).

## Going live with real M-Pesa (needs Safaricom/Vodacom)

1. Obtain Daraja **production** credentials (consumer key/secret, passkey,
   shortcode, initiator + security credential).
2. Set `MPESA_ENVIRONMENT=production` and the `MPESA_*` vars in `.env`.
3. Expose a **public HTTPS** callback URL and set `MPESA_CALLBACK_BASE_URL`.
   (For sandbox testing use an ngrok/Cloudflare tunnel.)
4. Prove the loop: top-up → STK prompt → webhook → `succeeded`.

## Mobile release (needs stores)

Point the app at prod: `--dart-define=TAIFA_USE_REMOTE=true
--dart-define=TAIFA_API_BASE_URL=https://api.taifa.co.tz`. Then build
`flutter build apk|appbundle|ipa` and submit to Play/App Store (signing certs +
store accounts required).

## Production payment gates (mandatory before real funds)

`python manage.py check` must pass with `DJANGO_DEBUG=false`. System checks
refuse unsafe payment config (`payments.E001`–`E006`). Full gate report:
[`PRODUCTION_GATE.md`](PRODUCTION_GATE.md).

Ops stack (Phase 2): [`OPERATIONS.md`](OPERATIONS.md),
[`OPERATIONS_READINESS.md`](OPERATIONS_READINESS.md).

```bash
docker compose -f docker-compose.prod.yml -f docker-compose.observability.yml --env-file .env up -d
```

Required env (minimum):

```bash
DJANGO_DEBUG=false
TAIFA_ALLOW_DEMO_WALLET_FUNDING=false
TAIFA_ALLOW_DEMO_STK=false
TAIFA_WITHDRAWAL_AUTO_APPROVE=false
MPESA_WEBHOOK_SHARED_SECRET=<rotate regularly>
# Prefer also:
MPESA_WEBHOOK_REQUIRE_HMAC=true
MPESA_WEBHOOK_FAIL_CLOSED=true
MPESA_WEBHOOK_ALLOWED_IPS=<Safaricom egress CIDRs>
RISK_PER_TXN_LIMIT_MINOR=500000000        # e.g. 5_000_000 TZS
RISK_DAILY_DEBIT_LIMIT_MINOR=2000000000
RISK_DAILY_CREDIT_LIMIT_MINOR=5000000000
# Do NOT set RISK_ALLOW_UNLIMITED without written approval
```

Daily ops:

```bash
python manage.py reconcile_ledger --json
python manage.py ingest_settlement_csv /path/to/provider.csv --reconcile
```

## Operational checklist

- [ ] `DJANGO_DEBUG=false` and a strong unique `DJANGO_SECRET_KEY`
- [ ] `DJANGO_ALLOWED_HOSTS` + `CORS_ALLOWED_ORIGINS` locked to real hosts
- [ ] Demo funding / demo STK / withdrawal auto-approve all **false**
- [ ] Webhook shared secret (+ HMAC / IP allow-list) configured
- [ ] Finite risk limits set; no unlimited without approval
- [ ] Postgres backups + PITR enabled
- [ ] Redis persistence/HA for the Celery broker
- [ ] `SENTRY_DSN` set; log shipping configured (see `docs/OBSERVABILITY.md`)
- [ ] Prometheus + Alertmanager rules loaded (`deploy/observability/`)
- [ ] TLS enforced end-to-end; HSTS on
- [ ] Rate limits reviewed for expected traffic
- [ ] Production gate doc signed off: [`PRODUCTION_GATE.md`](PRODUCTION_GATE.md)
