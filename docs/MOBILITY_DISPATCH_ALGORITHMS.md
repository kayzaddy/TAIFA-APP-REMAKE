# Dispatch Algorithms

## Ranking score (e4)

```
score =
  50000
  + rating_bonus
  + safety_bonus
  + acceptance_bonus
  + strategy_bonus
  - distance_penalty
  - queue_penalty
  - cross_station_penalty
```

ETA uses Haversine distance / 6 m/s with peak-hour traffic factor `1.35` at commute hours.

## Strategy matrix

| Strategy | Pool | Extra |
| --- | --- | --- |
| `station_first` | Home station queue | Default MDMP |
| `overflow` | Home + nearby district stations | Capacity / shortage triggered |
| `direct_nearby` | District/region | Redispatch widen |
| `priority` | Cross-station | Queue `priority` field boost |
| `corporate` | Prefer fleet matching `corporate_account` | Pricing corporate multipliers |
| `emergency` | Cross-station | Safety score heavily weighted |

## Recovery

Celery `mobility.expire_dispatch_offers` (15s): expire → `redispatch_trip`.

Escalation: `station_first` → `overflow` → `direct_nearby` → cancel + notify.
