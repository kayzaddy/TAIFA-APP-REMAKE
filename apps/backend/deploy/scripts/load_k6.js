#!/usr/bin/env bash
# k6 load scenarios for TAIFA payment API.
# Install: https://k6.io
# Usage: BASE_URL=http://localhost:8000 k6 run deploy/scripts/load_k6.js
#
# Stages: 10 → 100 → 1000 VUs (approximate TPS depends on scenario think-time).
import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  scenarios: {
    ramp: {
      executor: "ramping-arrival-rate",
      startRate: 10,
      timeUnit: "1s",
      preAllocatedVUs: 50,
      maxVUs: 2000,
      stages: [
        { target: 10, duration: "1m" },
        { target: 100, duration: "2m" },
        { target: 1000, duration: "3m" },
        { target: 0, duration: "1m" },
      ],
    },
  },
  thresholds: {
    http_req_failed: ["rate<0.01"],
    http_req_duration: ["p(95)<500"],
  },
};

const BASE = __ENV.BASE_URL || "http://localhost:8000";

export default function () {
  const health = http.get(`${BASE}/healthz`);
  check(health, { "healthz 200": (r) => r.status === 200 });
  const ready = http.get(`${BASE}/readyz`);
  check(ready, { "readyz 200": (r) => r.status === 200 });
  sleep(0.05);
}
