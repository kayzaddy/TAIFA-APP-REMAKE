# 02 — Product Standards

---

## Executive summary

Mandatory **product standards** for discovery, planning, documentation, and delivery—every product folder follows the same structure.

---

## Standard product repository layout

```
docs/products/{product-slug}/
  00_PRODUCT_CHARTER.md
  01_PRODUCT_VISION.md
  … (through 25_RETROSPECTIVE.md)
  /architecture/          # optional deep dives (link platform packs)
  /releases/              # release notes per version
```

**Existing packs** (pre-TPOS) may **map** to this standard—see [12_IMPLEMENTATION_GUIDE.md](12_IMPLEMENTATION_GUIDE.md). Example: [taifa-merchant](../taifa-merchant/00_INDEX.md) → migration map in implementation guide.

---

## Discovery standards

| Element | Required |
| --- | --- |
| Problem definition | Jobs-to-be-done statement |
| Market opportunity | TAM/SAM/SOM (indicative) |
| Customer segments | Primary / secondary |
| Competitive analysis | Table + differentiation |
| Stakeholder map | RACI for product |
| Business value | Qual + quant |
| Expected ROI | Model or ranges |
| Success metrics | Leading + lagging ([18_SUCCESS_METRICS.md](18_SUCCESS_METRICS.md)) |

---

## Planning standards

- Charter before vision expansion  
- Feature catalog **prioritized** (MoSCoW or RICE)  
- MVP scope in `20_MVP.md` — one page max executive summary + link to detail  
- Roadmap in `18_ROADMAP.md` aligned to [portfolio](../TAIFA_PRODUCT_PORTFOLIO_AND_DELIVERY_ROADMAP.md)

---

## Engineering standards

See [05_ENGINEERING_STANDARDS.md](05_ENGINEERING_STANDARDS.md)—**platform consumption mandatory**.

---

## Documentation quality bar

- Executive summary on every doc  
- Mermaid for flows where applicable  
- Version header: status, owner, last review date  
- Decision log for material changes (`24_DECISION_LOG.md`)

---

## Cross-references

[03_PRODUCT_DOCUMENT_TEMPLATE.md](03_PRODUCT_DOCUMENT_TEMPLATE.md) · [13_TEMPLATES.md](13_TEMPLATES.md)
