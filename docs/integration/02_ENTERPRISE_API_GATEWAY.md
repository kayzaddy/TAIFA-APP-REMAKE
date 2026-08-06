# 02 — Enterprise API Gateway

---

## Executive summary

**Enterprise API Gateway** for all Taifa north-south traffic: routing, authN/Z passthrough, validation, versioning, throttling, WAF, CloudFront—implements and extends [Core API Gateway](../platform/02_API_GATEWAY_PLATFORM.md).

---

## Business purpose

Single internal front door before service mesh east-west hops.

---

## Architecture overview

```mermaid
flowchart LR
  CF[CloudFront]
  WAF[WAF Shield]
  APIGW[API Gateway HTTP]
  AUTH[Lambda authorizers]
  VPC[VPC Link ALB]
  CF --> WAF --> APIGW --> AUTH --> VPC
```

---

## Features

REST/GraphQL ingress · OpenAPI validation · API versioning (`/v1`, headers) · rate limit & throttle · request/response transformation (mapping templates) · correlation `X-Taifa-Request-Id` · W3C trace context · mutual TLS for selected routes.

---

## API products (examples)

`taifa.core.*` · `taifa.payments.*` · `taifa.mobility.*` · `taifa.government.*`

---

## Sequence

```mermaid
sequenceDiagram
  participant C as Client
  participant G as Enterprise GW
  participant I as Identity
  participant S as Service
  C->>G: request
  G->>I: validate JWT
  G->>S: route
  S-->>C: response
```

---

## Operational considerations

Multi-account deployment; separate staging/prod APIs; blue/green stages.

---

## Implementation strategy

TIP-G1 gateway foundation sprint.

---

## Future expansion

GraphQL federation gateway.

---

## Cross-references

[10_OPENAPI_MANAGEMENT.md](10_OPENAPI_MANAGEMENT.md)
