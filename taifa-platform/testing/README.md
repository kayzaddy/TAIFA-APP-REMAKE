# Testing

**Owner:** QA + Engineering  
**Purpose:** Cross-cutting test harnesses—not per-package unit tests (those live next to code).

| Path | Use |
| --- | --- |
| `unit/` | Shared test utilities |
| `integration/` | Service integration suites |
| `e2e/` | End-to-end (staging) |
| `performance/`, `load/` | k6 / Gatling scenarios |
| `security/` | DAST, fuzz configs |
