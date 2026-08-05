# TAIFA Backend — Payment Service

The authoritative payment service: a **double-entry ledger**, a **Transaction
Engine**, and a **provider-abstracted gateway** with a real **M-Pesa (Daraja)**
adapter and a **Webhook Processor** that resolves async STK-push payments.

It is a deliberate mirror of the Flutter client's payment domain
(`apps/mobile/lib/features/wallet/`). The Dart interfaces are the spec, so the
two stay aligned by construction. See [`../../docs/PAYMENTS.md`](../../docs/PAYMENTS.md).

Stack: **Django 5 + DRF** (ORM, atomic transactions, migrations and admin — the
right tools for a ledger), **PostgreSQL**, **Celery + Redis** for async webhook /
retry work. A FastAPI read-edge can be added later for high-throughput queries.

---

## Layout

```
apps/backend/
├─ config/                 # Django project (settings, urls, celery, wsgi/asgi)
└─ payments/
   ├─ money.py             # Money + Currency (mirror of the Dart value objects)
   ├─ models.py            # LedgerAccount, LedgerEntry, Posting (append-only),
   │                       #   Transaction, IdempotencyKey, WebhookEvent
   ├─ ledger.py            # atomic, balanced double-entry posting + balances
   ├─ engine.py            # TransactionEngine: idempotent top-up + transfer
   ├─ webhooks.py          # Webhook Processor (resolves PaymentPending)
   ├─ gateways/
   │  ├─ base.py           # PaymentGateway ABC + sealed results (mirror of Dart)
   │  ├─ registry.py       # PaymentRouter (preference + fallback)
   │  ├─ mpesa.py          # REAL Daraja adapter (OAuth, STK push, B2C, query)
   │  ├─ simulated.py      # Airtel / Selcom / Card sandbox rails
   │  └─ factory.py        # assembles the default router from settings
   ├─ auth.py              # device-bound token authentication (Bearer + X-Device-Id)
   ├─ serializers.py / views.py / urls.py / admin.py
   └─ tests/               # 26 tests: money, ledger, router, engine, api, device auth
```

## Run locally (SQLite fallback — zero infra)

```bash
cd apps/backend
py -3.11 -m venv .venv
.venv\Scripts\pip install -r requirements.txt   # (Linux/macOS: .venv/bin/pip)
.venv\Scripts\python manage.py migrate
.venv\Scripts\python manage.py test payments     # 26 tests
.venv\Scripts\python manage.py runserver
```

> Python **3.11** — Django 5.x does not yet support 3.14.

### API docs (OpenAPI 3)

With the server running: Swagger UI at `/api/docs`, Redoc at `/api/redoc`, raw
schema at `/api/schema`. A generated `openapi.yaml` is committed and validated in
CI (`spectacular --fail-on-warn`). Health: `/healthz` (liveness), `/readyz`
(readiness — checks the DB). Metrics: `/metrics` (Prometheus). Ledger check:
`python manage.py reconcile_ledger`.

## Run production-shaped (Postgres + Redis + Celery + nginx)

```bash
cd apps/backend
cp .env.example .env   # set DJANGO_DEBUG=false, POSTGRES_PASSWORD, hosts, ...
docker compose -f docker-compose.prod.yml --env-file .env up -d --build
```

gunicorn behind nginx, with a one-shot `release` job (migrate + collectstatic)
that gates the web rollout. See [`../../docs/DEPLOYMENT.md`](../../docs/DEPLOYMENT.md).
The original `docker-compose.yml` remains for a simpler dev stack.

## API

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| POST | `/api/v1/auth/device/register` | open | Bind a device, mint a token, open a demo wallet |
| GET | `/api/v1/payments/wallet` | device | The device's balance + recent transactions |
| POST | `/api/v1/payments/topups` | device | STK-push top-up → `processing` (resolved by webhook) |
| POST | `/api/v1/payments/topups/{id}/demo-complete` | device | Gated demo STK success (DEBUG / `TAIFA_ALLOW_DEMO_STK`) |
| POST | `/api/v1/payments/transfers` | device | Send money to a recipient (routes to a rail) |
| GET | `/api/v1/payments/transactions/{id}` | device | Fetch one of the device's transactions |
| POST | `/api/v1/payments/webhooks/mpesa/stk` | open | Daraja STK result callback (Webhook Processor) |

`POST` money endpoints **require an `Idempotency-Key` header** — a replay returns
the original transaction and never moves money twice.

### Device-bound auth

The mobile client generates a stable `device_id`, registers once to receive an
opaque bearer token, then presents **both** on every call:

```
Authorization: Bearer <token>
X-Device-Id: <device_id>
```

Only the SHA-256 of the token is stored server-side; the plaintext is returned
exactly once. Every wallet read/write is scoped to the authenticated device's
`owner`, so a device can only ever see and move its own money.

```bash
# register (open) → { token, owner, balance_minor }
curl -X POST localhost:8000/api/v1/auth/device/register \
  -H 'Content-Type: application/json' -d '{"device_id":"demo-device-1"}'

# authenticated read
curl localhost:8000/api/v1/payments/wallet \
  -H 'Authorization: Bearer <token>' -H 'X-Device-Id: demo-device-1'
```

### Example: top-up + settlement

```bash
# 1) initiate (STK push sent to the customer's phone)
curl -X POST localhost:8000/api/v1/payments/topups \
  -H 'Content-Type: application/json' -H 'Idempotency-Key: demo-1' \
  -d '{"amount_minor":10000000,"currency":"TZS","msisdn":"+255754000891"}'
# → 201 {"status":"processing","provider_ref":"ws_CO_...","id":"..."}

# 2) Daraja calls this after the customer enters their PIN (simulated here)
curl -X POST localhost:8000/api/v1/payments/webhooks/mpesa/stk \
  -H 'Content-Type: application/json' \
  -d '{"Body":{"stkCallback":{"CheckoutRequestID":"ws_CO_...","ResultCode":0,"ResultDesc":"ok"}}}'

# Or (DEBUG / TAIFA_ALLOW_DEMO_STK): device confirms without Daraja
# curl -X POST localhost:8000/api/v1/payments/topups/<id>/demo-complete \
#   -H 'Authorization: Bearer <token>' -H 'X-Device-Id: demo-device-1'

# Or (live Daraja, no public callback): poll STK query after customer PIN
# curl -X POST localhost:8000/api/v1/payments/topups/<id>/poll-status \
#   -H 'Authorization: Bearer <token>' -H 'X-Device-Id: demo-device-1'

# 3) transaction is now settled, ledger posted
curl localhost:8000/api/v1/payments/transactions/<id> \
  -H 'Authorization: Bearer <token>' -H 'X-Device-Id: demo-device-1'   # → "succeeded"
```

> The examples above omit auth headers on `/topups` for brevity; in practice all
> money endpoints require the device token + id shown in **Device-bound auth**.

## Configuration

Copy `.env.example` → `.env`. Key vars: `DATABASE_URL`, `CELERY_BROKER_URL`,
and the `MPESA_*` Daraja credentials.

With `MPESA_CONSUMER_KEY` + `MPESA_CONSUMER_SECRET` set, the factory switches
from `OfflineMpesaGateway` to the live Daraja adapter. Sandbox uses shortcode
`174379` and Safaricom’s published Lipa Na M-Pesa Online passkey when
`MPESA_PASSKEY` is empty. Verify OAuth:

```bash
python manage.py check_daraja
python manage.py reconcile_ledger   # books-balanced check (exit 1 on breaks)
```

For real STK **webhooks** (not just poll-status), expose the backend with ngrok
and set `MPESA_CALLBACK_BASE_URL` to the HTTPS origin (no trailing path):

```bash
ngrok http 8000
# then in apps/backend/.env:
# MPESA_CALLBACK_BASE_URL=https://<your-subdomain>.ngrok-free.dev
# restart runserver so STK CallBackURL picks it up
```

Daraja will POST `{MPESA_CALLBACK_BASE_URL}/api/v1/payments/webhooks/mpesa/stk`.
Without a public URL, settle pending top-ups with `POST …/poll-status` after PIN.
Without credentials the offline STK + `demo-complete` path still works.

## Invariants worth knowing

- **Ledger is append-only** — enforced in the ORM (`AppendOnly`) *and* by a
  PostgreSQL trigger (`0002_append_only_guards`, no-op on SQLite).
- **Every entry balances** — `post_entry` refuses to write postings that don't
  net to zero per currency, inside a DB transaction.
- **Exactly-once** — `IdempotencyKey` rows dedupe retries.
- **Nothing is lost** — raw provider callbacks are persisted as `WebhookEvent`
  before processing.
