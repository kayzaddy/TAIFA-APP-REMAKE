# 04 — UX Standards

---

## Executive summary

Taifa **UX standards**: navigation, flows, accessibility, responsive design, design tokens, design system usage, component standards.

---

## Design system

- **Source of truth:** Taifa Design System (TDS)—tokens, typography, color, spacing (product teams consume; extensions via PR to design system).  
- **Platforms:** Web (responsive), Flutter (super-app + product apps), future design-system Figma library.

---

## Navigation standards

- Max 5 primary destinations mobile bottom nav; secondary in “More”.  
- Merchant/gov apps: role-based nav (owner vs cashier).  
- Breadcrumbs web ≥ 3 levels deep.  
- Back behavior consistent with platform (Android/iOS).

---

## UX flow standards

- Every flow diagram in `09_UX_FLOW.md` with: entry, success, error, empty, loading, offline (if applicable).  
- Maximum 3 taps to primary action for cashier flows.  
- Confirm destructive actions (refunds, delete).

---

## Accessibility

- **WCAG 2.1 AA** minimum for public products.  
- Swahili + English copy; plain language.  
- Touch targets ≥ 44dp; contrast ratios per TDS.  
- Screen reader labels on all interactive elements.

---

## Responsive design

- Mobile-first; breakpoints: 360, 768, 1024, 1280.  
- Merchant web: usable on tablet for back-office.

---

## Design tokens & components

| Layer | Standard |
| --- | --- |
| Tokens | Color, type, radius, elevation from TDS |
| Components | Use TDS; no one-off buttons without design approval |
| `11_COMPONENT_MAP.md` | Maps screens → TDS components |

---

## Review

**Design Review Board** before implementation—see [10_PRODUCT_GOVERNANCE.md](10_PRODUCT_GOVERNANCE.md).

---

## Cross-references

[14_CHECKLISTS.md](14_CHECKLISTS.md) · Design Review checklist
