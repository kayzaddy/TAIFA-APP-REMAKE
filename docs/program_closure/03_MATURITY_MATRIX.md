# 3. Platform Maturity Matrix

**As of:** 2026-07-19  
**Levels:** L0–L7 per Certification Manual · Status tags: COMPLETE | IN PROGRESS | PILOT | CERTIFIED | BLOCKED  

| Platform | Level | Status | Milestones done | Outstanding | Risks | Ops ready | Business ready | Cert | Next action |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Identity (device) | L5 | COMPLETE | Auth, tokens, scoping | Full KYC product UX | Medium | Yes | Partial | Arch/Eng/Sec strong | Harden KYC journeys |
| Payments | L5–L6 | IN PROGRESS | Ledger, rails, gates | Live creds all rails | High if creds missing | Yes | Env-dependent | Production gate docs | Install operator creds |
| Ledger | L5–L6 | COMPLETE | Double-entry SoT | Continuous audit | Critical if bypassed | Yes | N/A | Strong | Protect invariant |
| Wallet | L4–L5 | COMPLETE foundation | Mobile + API | Product depth | Medium | Yes | Partial | Eng strong | Pilot usage metrics |
| Mobility | L3–L4 | IN PROGRESS | Trip loop, maps mock | National evidence | Medium | Partial | Partial | Not national | Controlled city pilots |
| Winga | L4 | PILOT | Brokerage+exp+ops | Field Hotels 0 txns | Medium | Handbook yes | **BLOCKED** | Not business-cert | Run Hotels field pilot |
| Commerce MOS | L3–L4 | PILOT | MOS+exp+ops | 0 certified merchants | Medium | Handbook yes | **BLOCKED** | Not business-cert | Merchant pilot |
| AI Platform | L3–L4 | IN PROGRESS | Assist + guards | Model ops maturity | High if misused | Partial | Assist-only | AI policy enforced | Monitor assist abuse |
| Governance API | L4 | COMPLETE | Scorecard API | Exec adoption | Low | Yes | N/A | Meta | Weekly scorecard ritual |
| Integrations fabric | L2–L3 | BLOCKED (national) | Catalog + cert API | Operator credentials | High | Partial | NO-GO national | Integration cert NO-GO | Credential onboarding |
| Government / Health / Edu / Agri / Tourism / Housing / Employment / Insurance | L1–L2 | IN PROGRESS / demo | Vertical demos | Full MOS lifecycle | Varies | Low | Low | Not started G0–G7 | Enter Stage 0 under Constitution |

**Legend:** Business ready = real users + measured value. Feature-complete ≠ business-certified.
