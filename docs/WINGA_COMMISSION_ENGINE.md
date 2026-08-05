# Winga Commission Engine Guide

## Rule kinds

| Kind | Behavior |
| --- | --- |
| `percentage` | `amount * bps / 10000` |
| `flat` | Fixed `flat_minor` |
| `tiered` | Match `tiers[]` by amount band → bps |
| `category` / `provider` / `campaign` | Same as percentage with scoped rule |
| `referral_bonus` | Percentage scoped to campaign/winga |
| `multi_level` | Multiple lines from `multi_level[]` |

## Selection order

1. Active rules matching domain / category / provider / winga
2. Validity window
3. Lowest `priority`, then highest specificity (winga > provider > category > domain)

If none match → `BrokerageDomain.default_commission_bps`.

## Settlement

- Events start as `calculated`
- `settle_commissions` → `settled` + ledger txn id
- Refunds / disputes → `reversed` (money reverse via payments refund path)

## Configuration example

```json
{
  "code": "hotels-peak",
  "kind": "tiered",
  "domain": "<hotels-uuid>",
  "priority": 50,
  "tiers": [
    {"min_minor": 0, "max_minor": 20000000, "bps": 1200},
    {"min_minor": 20000001, "max_minor": null, "bps": 800}
  ]
}
```

API: `POST /api/v1/winga/commission-rules`
