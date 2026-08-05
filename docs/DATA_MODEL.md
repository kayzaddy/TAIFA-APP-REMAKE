# TAIFA Data Model

The source of truth is Postgres. The payment schema is **built and migrated**;
other domains are specified here so they slot in behind the same conventions.

**Enterprise concepts (owners, lifecycles):** [`platform/earb/03_CANONICAL_DATA_MODEL.md`](platform/earb/03_CANONICAL_DATA_MODEL.md).  
**Schema ownership rules:** [`architecture/04_DATABASE_STANDARDS.md`](architecture/04_DATABASE_STANDARDS.md).  
**Tourism table ownership:** [`tourism/CANONICAL_ENTERPRISE_ARCHITECTURE.md`](tourism/CANONICAL_ENTERPRISE_ARCHITECTURE.md) §7.

## Conventions

- **Money** = integer minor units + currency code; never floats.
- **Immutability** where it matters: ledger entries and postings are append-only
  (ORM guard + Postgres trigger); transactions carry the mutable lifecycle.
- **Idempotency** on all money writes.
- **Owner scoping**: money rows carry an `owner`; every query is filtered by the
  authenticated principal.
- **UUID PKs** for externally-visible entities (non-enumerable).

## Payments (implemented — `apps/backend/payments/models.py`)

```
Device(id, device_id⊙, token_hash, owner, label, platform, created_at, last_seen_at)
   └─ authenticates ▶ owner

LedgerAccount(id⊙ "user:{owner}:wallet:TZS" | "house:*", account_type, currency, owner)
LedgerEntry(id, transaction→, description, created_at)              [append-only]
   └─ Posting(id, entry→, account→, direction, amount_minor, currency)  [append-only]
        invariant: Σ signed postings == 0 per currency

Transaction(id, owner⊙, type, status, direction, amount_minor, fee_minor,
            currency, counterparty, method_kind, method_ref, operator,
            idempotency_key⊙, note, provider, provider_ref⊙, ledger_entry→1:1,
            created_at, updated_at)

IdempotencyKey(key⊙, scope, request_hash, status, transaction→, response_*)
WebhookEvent(id, provider, event_type, provider_ref⊙, payload, processed, result, …)
```

`⊙` = indexed / unique-ish. Balances are always `Σ postings` for an account —
never a stored mutable number — which keeps the books reconstructable and
auditable.

### Why double-entry
Every movement debits one account and credits another (plus fee/tax splits), and
the entry refuses to persist unless it nets to zero per currency. A bug throws at
write time instead of silently drifting balances.

## Identity & KYC (planned)

```
User(id, phone⊙, status, created_at)              # phone-first identity
Profile(user→1:1, full_name, lang, avatar, …)
KycRecord(user→, tier{0..3}, id_type, id_ref, verified_at, provider_ref)
Device.owner  ⟶  becomes  User.id   (today: synthetic dev_* owner)
```

Migration path: the current synthetic `owner` (`dev_<device>`) is replaced by a
real `User.id` once identity ships; wallet account keys already namespace by
owner, so ledger identifiers are stable.

## Commerce / mobility (planned, illustrative)

```
Merchant(id, owner→User, name, mcc, payout_account, status)
Order(id, buyer→User, merchant→, amount_minor, currency, status, created_at)
   └─ links to Transaction for settlement
Trip(id, rider→User, driver→User, origin, dest, fare_minor, status, timestamps)
Vehicle / DriverProfile / PricingRule …
```

All monetary settlement routes through the **same** payment engine + ledger, so
commerce/mobility never re-implement money handling.

## Multi-tenancy & partitioning (target)

- **Regioning**: a `region` dimension on money-bearing rows for data residency
  (TZ/KE/UG); read replicas per region.
- **Partitioning**: `LedgerEntry`/`Posting`/`Transaction` partitioned by month
  for retention and query performance at scale.
- **Retention**: hot (recent) vs. cold (archived) ledger partitions; webhook
  payloads TTL'd after reconciliation.

## Integrity guarantees (today)

- Append-only ledger (ORM + trigger `migrations/0002`).
- Balanced entries enforced in a DB transaction (`ledger.post_entry`).
- Exactly-once via `IdempotencyKey`.
- Owner-scoped access on every read/write.
