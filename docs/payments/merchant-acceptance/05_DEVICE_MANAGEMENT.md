# 05 — Device Management (Acceptance)

---

## Executive summary

Acceptance-layer **device lifecycle**: registration, activation, certificates, revocation, monitoring, inventory, firmware tracking (future), remote disable—extends [Merchant Platform device registry](../merchant/05_DEVICE_MANAGEMENT.md) with runtime acceptance state.

---

## Business purpose

Trusted endpoints for SoftPOS and QR terminals.

---

## Architecture

```mermaid
flowchart TB
  MER_REG[Merchant Platform Device Registry] --> MAP_DEV[MAP Device Runtime]
  MAP_DEV --> CERT[Certificate Service]
  MAP_DEV --> HEALTH[Device Health]
  MAP_DEV --> OFF[Offline Policy]
```

---

## Sequence: activation

```mermaid
sequenceDiagram
  participant App as SoftPOS App
  participant MAP as MAP Device API
  participant MER as Merchant Platform
  App->>MAP: activate {device_id, attestation}
  MAP->>MER: verify device + merchant
  MAP->>MAP: issue acceptance cert
  MAP-->>Bus: merchant.device.online
```

---

## State diagram

```mermaid
stateDiagram-v2
  [*] --> registered
  registered --> active: activate
  active --> offline: heartbeat_miss
  offline --> active: heartbeat
  active --> revoked: remote_disable
  revoked --> [*]
```

---

## API / events / DB

[07](07_API_SPECIFICATION.md) · `merchant.device.online/offline` · [09](09_DATABASE_MODEL.md)

---

## Security

Cert rotation; remote wipe command.

---

## AWS

IoT optional future; Redis last_seen.

---

## Implementation strategy

Single `device_id` across Merchant + MAP schemas via reference.

---

## Operational model

NOC dashboard for offline fleet.

---

## Future expansion

Hardware POS firmware channel.

---

## Cross-references

[merchant/05_DEVICE_MANAGEMENT.md](../merchant/05_DEVICE_MANAGEMENT.md)
