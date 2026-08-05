# Winga Property — Architecture (Phase 1)

```
Owner (Taifa Identity principal)
        │
        ▼
 PropertyOwner profile
        │
        ▼
 PropertyListing ──► PropertyMedia (photo / video)
        │                    │
        │                    └── optional winga.Offering link (brokerage)
        ▼
 Verification workflow (PropertyVerificationEvent audit)
        │
        ▼
 Discovery API (search, map pins, favorites, saved searches)
        │
        ▼
 Flutter WingaPropertyScreen (/winga-property)
```

## Design principles

1. **Do not duplicate** payments, identity, or full brokerage logic.
2. **PropertyListing** is source of truth for discovery; `winga.Offering` is optional for deal settlement later.
3. **Media** uses URL references in Phase 1; S3 upload adapter in Phase 3.
4. **Verification** is auditable — every status change logged.

## Models

| Model | Purpose |
| --- | --- |
| `PropertyCategory` | residential / commercial / land |
| `PropertyType` | apartment, house, office, plot, … |
| `PropertyOwner` | owner / agent / landlord account |
| `PropertyListing` | core listing + geo + pricing |
| `PropertyMedia` | photos and videos |
| `PropertyFavorite` | per-principal favorites |
| `SavedSearch` | persisted filter JSON |
| `PropertyVerificationEvent` | verification audit trail |
