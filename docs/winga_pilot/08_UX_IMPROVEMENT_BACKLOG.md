# 8. UX Improvement Backlog — Evidence-Based

Prioritized by **business impact** on Hotels pilot exit criteria.  
No architecture redesign. Experience-layer or ops-config only unless marked.

| ID | Severity | Persona | Problem | Proposed fix | Impact |
| --- | --- | --- | --- | --- | --- |
| O-01 | High | Ops / Finance | No HTTP APITestCase for pay/settle | Add API tests mirroring settlement unit test | Audit confidence |
| C-01 | High | Customer | Stage labels may not match hotel mental model | Hotels copy map (Inquiry→Request, Fulfillment→Stay) | Completion |
| C-02 | High | Customer | Trust before first pay | Surface KYB + rating + completed stays on offering | Conversion |
| W-01 | High | Winga | TTFC unclear | “Path to first commission” checklist on desk | Activation |
| W-02 | Medium | Winga | Opportunity apply is local prefs | Persist apply intent to lead/campaign when API available | Liquidity |
| P-01 | Medium | Provider | Campaign creation not self-serve | Provider checklist + ops-assisted rule create | Retention |
| P-02 | Medium | Provider | Lead quality opaque | Show Winga reputation + lead source on inbound | Trust |
| C-03 | Medium | Customer | Quote expiry not always visible | Countdown on quote / offer cards | Acceptance |
| N-01 | Medium | All | Notification fatigue risk | Hotels pilot allowlist only (lead, quote, pay, settle) | Retention |
| A-01 | Medium | All | Funnel drop-off not instrumented | Lightweight event log Discover→Pay | Decisions |
| C-04 | Low | Customer | Review UX shallow | Post-stay prompt with 1–5 + comment | Quality |
| W-03 | Low | Winga | Leaderboard absent | Optional weekly GMV board (ops sheet OK for pilot) | Motivation |
| D-01 | Low | All | Formal PDF voucher | Generate from deal + payment_ref | Support load |

**Rule:** Ship only items that unblock exit criteria or Critical/High defects found in field.
