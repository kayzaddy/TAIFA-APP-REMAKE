# TAIFA Payment Architecture

> **Enterprise program:** [Taifa National Payment Infrastructure (TNPI)](payments/README.md) — acceptance & orchestration layer (not a consumer wallet). This document describes the **current implementation** ledger and provider abstraction evolving under TNPI.

The payment domain is the highest-value and highest-risk part of TAIFA. This
document describes the contract that lets any mobile-money operator, aggregator,
bank or card scheme plug in **without changing business logic** — and the ledger
that keeps money provably conserved.

It is implemented **twice, identically**:

- **Client** — `apps/mobile/lib/features/wallet/` (Dart).
- **Server (authoritative)** — `apps/backend/payments/` (Django + DRF), backed by
  PostgreSQL, with a real M-Pesa Daraja adapter and a webhook processor. See
  [`../apps/backend/README.md`](../apps/backend/README.md).

The Dart interfaces are the spec; the server mirrors them so the two stay aligned
by construction.

---

## 1. Money & currency (`domain/money.dart`, `domain/currency.dart`)

- **`Money`** stores an integer count of **minor units** in one `Currency`.
  All arithmetic is exact — `double` is never used for value, so balances, fees
  and postings never drift. Cross-currency arithmetic throws.
- **`Currency`** is the single registry of supported currencies (TZS, USD, EUR,
  KES, UGX, BTC) with storage precision (`minorUnitDigits`) and display precision
  (`displayDigits`). Adding a currency/crypto asset is one enum entry.
- **`CurrencyEngine`** converts for display/quotes. Seed rates are static; the
  interface is stable so live mid-market rates + spread policy slot in behind it.
  Settlement always uses the rate captured at authorisation, never a display rate.

## 2. Double-entry ledger (`domain/ledger.dart`)

- **`LedgerAccount`** — typed accounts: `userWallet`, `providerSettlement`,
  `externalMobileMoney`, `externalBank`, `feeIncome`, `taxPayable`, `cryptoVault`,
  `suspense`.
- **`Posting`** — a movement against one account with a `direction`
  (debit/credit). Convention: **debit = +, credit = −**.
- **`LedgerEntry`** — immutable, append-only. Its constructor **asserts the
  postings net to zero within every currency** (`UnbalancedLedgerEntry` otherwise).
  This is the single most important invariant in the system: a bug throws rather
  than silently corrupting balances.

Example — a TSh 100,000 transfer with a TSh 500 fee:

```
DEBIT  user:wallet            100,500
CREDIT house:provider-settle  100,000
CREDIT house:fee-income           500
                              ---------
net                                 0   ✓
```

## 3. Provider abstraction (`payments/`)

```
PaymentRequest ──▶ PaymentRouter ──▶ PaymentGateway (interface)
                                       ├─ MpesaGateway
                                       ├─ AirtelMoneyGateway
                                       ├─ SelcomGateway (aggregator/fallback)
                                       └─ CardGateway
        result ◀── sealed PaymentResult { Accepted | Pending | Failed }
```

- **`PaymentGateway`** — the one seam every rail implements: `charge`, `payout`,
  `refund`, `status`, plus `canHandle` (capability + currency + limits) and
  advertised `capabilities`.
- **`PaymentResult`** is **sealed** — callers must handle `PaymentAccepted`
  (settled), `PaymentPending` (async, await webhook/poll) and `PaymentFailed`
  (with `retryable`) exhaustively. No "unknown state" money bugs.
- **`PaymentRouter`** resolves an intent to a concrete rail using a preference
  order (direct operator first, Selcom aggregator as fallback) and graceful
  degradation. **Business logic never names a provider.**
- **Idempotency** (`idempotency.dart`) — every request carries a key generated
  per user intent; a durable store dedupes retries so money moves exactly once.

### Adding a new provider

1. Add an entry to the `PaymentProvider` enum.
2. Write one class implementing `PaymentGateway` (or extend
   `SimulatedGatewayBase` for sandbox).
3. Register it in `paymentGatewaysProvider`.

That's it — router, ledger, controller, UI and tests are untouched.

## 4. Send flow — controller + repository (`application/`)

`WalletController.sendMoney` runs the client-side guards for snappy UX, then
**delegates execution to the `WalletRepository`** — the authority that actually
moves the money:

```
balance guard → build TransferCommand (idempotency key)
   → repository.transfer(command)
   → reflect the returned TransferReceipt into UI state
```

The repository interface has two implementations, selected at runtime, and the
UI depends only on the interface:

- **`RestWalletRepository`** (`data/wallet/`) — the live path. `transfer()` calls
  `POST /payments/transfers` with the `Idempotency-Key` header; `load()` reads
  `GET /payments/wallet`. The **server owns the ledger**, so the receipt carries
  no client ledger entry.
- **`SeedWalletRepository`** — the offline/demo path. It exercises the *client*
  `PaymentRouter` and posts a local balanced `LedgerEntry`, so the provider
  abstraction and the zero-sum invariant stay live with no backend running.

`PaymentPending` surfaces as a `processing` transaction; a declined/failed
transfer leaves the balance untouched.

## 4b. Client ↔ server wiring (`apps/mobile/lib/data/`)

The `data/` layer is the only place that knows about HTTP:

```
data/
├─ api/     ApiConfig (versioned base URL) · TaifaApiClient + HttpApiClient · ApiException
├─ auth/    DeviceIdentity (stable id) · DeviceSession (device-bound token)
├─ dto/     TransactionDto · WalletDto  (wire JSON ⇄ domain)
└─ wallet/  RestWalletRepository
```

- **Device-bound tokens** — `DeviceSession` generates a stable `device_id`,
  registers once (`POST /auth/device/register`) to obtain a bearer token, and
  attaches `Authorization: Bearer <token>` + `X-Device-Id` to every call. A 401
  invalidates the token and re-registers once, transparently.
- **Versioned client** — `HttpApiClient` targets `/api/v1`, encodes JSON, sets the
  idempotency key, applies a timeout, and maps failures to `ApiException` →
  `WalletException` so the UI never sees raw HTTP.
- **Enable the backend** —
  `--dart-define=TAIFA_USE_REMOTE=true --dart-define=TAIFA_API_BASE_URL=http://10.0.2.2:8000`.
  Off by default so the app also runs fully offline on the seed.
- **Zero UI changes** — the wallet screens already depend only on
  `WalletController` / `WalletRepository`; swapping in the REST repository is the
  entire integration.

## 5. What is seeded vs. real

| Concern | Today | Next |
|---------|-------|------|
| Gateways | simulated (latency + outcomes) | real SDKs (Daraja, Airtel, Selcom, acquirer) |
| Ledger | in-memory, append-only | Postgres, event-sourced, partitioned |
| Idempotency store | in-memory (client) / Postgres (server) | Redis + Postgres durable |
| FX rates | static | live feed + spread policy |
| Auth | device-bound token (server-issued) | + user identity, biometric, step-up MFA |
| Wallet profile | static scaffolding (card, recipients) | profile service |

## 6. Deferred engines (interfaces exist or are stubbed)

Fee Engine, Settlement Engine, Reconciliation, Refund/Dispute, Fraud/Anomaly,
Tax Engine, Receipt Engine, Webhook Processor, Retry Engine — each will attach at
the marked seams without reshaping the core.

## 7. Server implementation (`apps/backend/payments/`)

Django + DRF service that promotes this model into durable infrastructure:

- **Schema** — append-only `LedgerEntry`/`Posting`, plus `Transaction`,
  `IdempotencyKey`, `WebhookEvent`. Append-only is enforced in the ORM *and* by a
  PostgreSQL trigger (`0002_append_only_guards`).
- **Ledger service** (`ledger.py`) — `post_entry` writes a balanced entry inside a
  DB transaction or refuses (same zero-sum invariant as the client).
- **Transaction Engine** (`engine.py`) — idempotent `initiate_topup` (STK-push
  charge) and `initiate_transfer` (payout); posts the ledger on terminal success.
- **Real M-Pesa Daraja adapter** (`gateways/mpesa.py`) — OAuth, STK push, B2C
  payout, STK query; collection returns `PaymentPending`.
- **Webhook Processor** (`webhooks.py`) — persists the raw callback, matches it to
  a transaction by `provider_ref`, and drives it to `succeeded`/`failed`.
- **Webhook trust** (`webhook_auth.py`) — optional `MPESA_WEBHOOK_ALLOWED_IPS`
  (IP/CIDR) and `MPESA_WEBHOOK_SHARED_SECRET` (`X-TAIFA-Mpesa-Webhook-Secret`),
  plus structural validation of `Body.stkCallback.CheckoutRequestID`.
- **Ledger reconciliation** (`reconciliation.py`) — `python manage.py reconcile_ledger`
  (or Celery `payments.reconcile_ledger`) asserts books balanced; metrics under
  `taifa_ledger_reconciliation_*` (see `OBSERVABILITY.md`).
- **Journal** (`journal.py`) — sole posting recipes for opening, top-up, transfer,
  withdrawal hold/release/settle, refund, reversal. See `PAYMENT_ENGINE.md`.
- **Withdrawals / refunds / reversals** — `POST /withdrawals` (+ approve/reject/process),
  `POST /refunds`, `POST /transactions/{id}/reverse`; all idempotent and ledger-backed.
- **Device auth** (`auth.py`) — bearer token bound to `X-Device-Id`; every
  transaction is scoped to the authenticated device's `owner`.
- **API** — `POST /auth/device/register` (open), `GET /payments/wallet`,
  `POST /payments/topups`, `POST /payments/transfers` (both require
  `Idempotency-Key`), `GET /payments/transactions/{id}`,
  `POST /payments/webhooks/mpesa/stk`.

## 8. Tests

**Client** — `apps/mobile/test/wallet/`: money math/formatting, ledger balance
invariant + immutability, routing (fallback, unsupported currency), end-to-end
send, and **`RestWalletRepository`** against a fake API client (contract mapping,
idempotency header, 422 + declined handling).

**Server** — `apps/backend/payments/tests/` (26 tests): money, ledger
(balance/immutability/atomicity), router, engine (top-up→**webhook resolves
pending**, transfer, idempotency, insufficient funds), HTTP API + webhook, and
**device auth** (register, token rotation, unauthorized access, owner-scoped
wallet reads).
