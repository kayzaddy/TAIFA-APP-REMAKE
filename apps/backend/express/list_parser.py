"""Smart Shopping List parser — dedicated Express path (not AI authorize)."""
from __future__ import annotations

import re
from difflib import SequenceMatcher
from typing import Any

from .models import ExpressProduct

# Word quantities (EN + common SW approximations)
_WORD_QTY = {
    "one": 1,
    "a": 1,
    "an": 1,
    "two": 2,
    "three": 3,
    "four": 4,
    "five": 5,
    "six": 6,
    "seven": 7,
    "eight": 8,
    "nine": 9,
    "ten": 10,
    "dozen": 12,
    "moja": 1,
    "mbili": 2,
    "tatu": 3,
    "nne": 4,
    "tano": 5,
}

# Synonyms / abbreviations / local names → catalog tokens
_SYNONYMS: dict[str, list[str]] = {
    "oil": ["oil", "cooking oil", "cook oil"],
    "cooking oil": ["oil", "cooking oil"],
    "cook oil": ["oil", "cooking oil"],
    "unga": ["flour"],
    "maziwa": ["milk"],
    "mkate": ["bread"],
    "mayai": ["eggs", "egg"],
    "egg": ["eggs", "egg"],
    "eggs": ["eggs", "egg"],
    "sukari": ["sugar"],
    "maji": ["water"],
    "sabuni": ["soap"],
    "para": ["paracetamol"],
    "panadol": ["paracetamol"],
    "detergent": ["detergent"],
    "wipes": ["baby wipes", "wipes"],
    "diaper": ["diapers"],
    "diapers": ["diapers"],
}

_UNIT_RE = re.compile(
    r"(?P<qty>\d+(?:\.\d+)?)\s*(?P<unit>kg|g|l|ml|pcs?|pack|pkt)?$",
    re.I,
)
_LEADING_QTY = re.compile(
    r"^(?P<qty>\d+(?:\.\d+)?)\s*[x×]?\s*(?P<name>.+)$",
    re.I,
)
_TRAILING_X = re.compile(
    r"^(?P<name>.+?)\s*[x×]\s*(?P<qty>\d+(?:\.\d+)?)\s*(?P<unit>kg|g|l|ml)?$",
    re.I,
)
_TRAILING_QTY = re.compile(
    r"^(?P<name>.+?)\s+(?P<qty>\d+(?:\.\d+)?)(?P<unit>kg|g|l|ml|pcs?)?$",
    re.I,
)


def _normalize_spaces(text: str) -> str:
    return re.sub(r"\s+", " ", (text or "").strip())


def _spell_fix(token: str) -> str:
    """Lightweight typo fixes for common staples."""
    fixes = {
        "milkk": "milk",
        "bred": "bread",
        "bredd": "bread",
        "egs": "eggs",
        "egss": "eggs",
        "sope": "soap",
        "tomatos": "tomatoes",
        "tomatoe": "tomatoes",
        "suger": "sugar",
        "flouer": "flour",
        "chiken": "chicken",
        "oill": "oil",
    }
    return fixes.get(token.lower(), token)


def parse_line(raw: str) -> dict[str, Any] | None:
    """Parse one shopping-list line into name / qty / unit."""
    line = _normalize_spaces(raw)
    if not line or line.startswith("#"):
        return None

    qty = 1
    unit = ""
    name = line

    # "Two Milk"
    parts = line.split()
    if parts and parts[0].lower() in _WORD_QTY and len(parts) > 1:
        qty = _WORD_QTY[parts[0].lower()]
        name = " ".join(parts[1:])
    elif m := _LEADING_QTY.match(line):
        qty = float(m.group("qty"))
        name = m.group("name").strip()
        # "2L Milk" style already captured qty; strip unit from name if glued
        if um := re.match(r"^(?P<unit>kg|g|l|ml)\s+(?P<rest>.+)$", name, re.I):
            unit = um.group("unit").lower()
            name = um.group("rest")
    elif m := _TRAILING_X.match(line):
        name = m.group("name").strip()
        qty = float(m.group("qty"))
        unit = (m.group("unit") or "").lower()
    elif m := _TRAILING_QTY.match(line):
        # Prefer unit-aware trailing: "Milk 2L", "Rice 5kg"
        maybe_unit = (m.group("unit") or "").lower()
        if maybe_unit:
            name = m.group("name").strip()
            qty = float(m.group("qty"))
            unit = maybe_unit
        else:
            # Ambiguous "Eggs 30" → treat as qty
            name = m.group("name").strip()
            qty = float(m.group("qty"))

    # Unit glued on name: "Milk2L"
    if um := re.search(r"(?P<n>.+?)(?P<q>\d+(?:\.\d+)?)(?P<u>kg|g|l|ml)$", name, re.I):
        if not unit:
            name = um.group("n").strip()
            qty = float(um.group("q"))
            unit = um.group("u").lower()

    name = _spell_fix(_normalize_spaces(name))
    if not name:
        return None

    # Plural soft-normalize
    tokens = [_spell_fix(t) for t in name.lower().split()]
    name_norm = " ".join(tokens)

    qty_i = int(qty) if float(qty).is_integer() else qty
    return {
        "raw": raw.strip(),
        "name": name_norm.title() if len(name_norm) < 40 else name_norm,
        "name_key": name_norm,
        "qty": qty_i if isinstance(qty_i, int) else float(qty),
        "unit": unit,
    }


def _candidates_for(name_key: str) -> list[str]:
    keys = [name_key]
    if name_key in _SYNONYMS:
        keys.extend(_SYNONYMS[name_key])
    for syn, targets in _SYNONYMS.items():
        if name_key in targets or name_key == syn:
            keys.extend(targets)
            keys.append(syn)
    # Drop trailing 's'
    if name_key.endswith("s") and len(name_key) > 3:
        keys.append(name_key[:-1])
    return list(dict.fromkeys(keys))


def _score_product(product: ExpressProduct, keys: list[str]) -> float:
    pname = product.name.lower()
    tags = " ".join(product.tags or []).lower()
    best = 0.0
    for key in keys:
        if key == pname or key in pname.split():
            best = max(best, 1.0)
        elif key in pname or key in tags:
            best = max(best, 0.92)
        else:
            best = max(best, SequenceMatcher(None, key, pname).ratio())
            for tag in product.tags or []:
                best = max(best, SequenceMatcher(None, key, str(tag).lower()).ratio())
    return best


def match_product(
    *,
    name_key: str,
    products: list[ExpressProduct],
    min_score: float = 0.55,
) -> tuple[ExpressProduct | None, list[dict[str, Any]]]:
    keys = _candidates_for(name_key)
    scored: list[tuple[float, ExpressProduct]] = []
    for p in products:
        s = _score_product(p, keys)
        if s >= min_score:
            scored.append((s, p))
    scored.sort(key=lambda t: (-t[0], -t[1].stock_qty, t[1].price_minor))
    if not scored:
        return None, []
    best = scored[0][1]
    alts = [
        {
            "product_id": str(p.id),
            "name": p.name,
            "sku": p.sku,
            "price_minor": p.price_minor,
            "store_name": p.store.name,
            "score": round(s, 3),
        }
        for s, p in scored[1:4]
    ]
    return best, alts


def parse_shopping_list(
    *,
    text: str,
    customer_lat: float | None = None,
    customer_lng: float | None = None,
) -> dict[str, Any]:
    """Parse multiline list → matched basket lines (inventory-aware)."""
    from .services import rank_stores  # local import avoids cycle

    lines_in = [ln for ln in (text or "").splitlines()]
    parsed_rows: list[dict[str, Any]] = []
    for ln in lines_in:
        row = parse_line(ln)
        if row:
            parsed_rows.append(row)

    # Merge duplicates by name_key (+ unit)
    merged: dict[str, dict[str, Any]] = {}
    for row in parsed_rows:
        key = f"{row['name_key']}|{row.get('unit') or ''}"
        if key in merged:
            merged[key]["qty"] = float(merged[key]["qty"]) + float(row["qty"])
            if float(merged[key]["qty"]).is_integer():
                merged[key]["qty"] = int(merged[key]["qty"])
        else:
            merged[key] = dict(row)
    parsed_rows = list(merged.values())

    names = [r["name_key"] for r in parsed_rows]
    lat = customer_lat if customer_lat is not None else -6.75
    lng = customer_lng if customer_lng is not None else 39.28
    ranking = rank_stores(customer_lat=lat, customer_lng=lng, product_names=names)
    products: list[ExpressProduct] = list(
        ExpressProduct.objects.filter(active=True, store__active=True).select_related("store")
    )
    # Prefer inventory from top-ranked store when available
    preferred_store_id = ranking[0]["store_id"] if ranking else None
    if preferred_store_id:
        preferred = [p for p in products if str(p.store_id) == preferred_store_id]
        others = [p for p in products if str(p.store_id) != preferred_store_id]
        products = preferred + others

    matched: list[dict[str, Any]] = []
    unknown: list[dict[str, Any]] = []
    for row in parsed_rows:
        product, alts = match_product(name_key=row["name_key"], products=products)
        if product is None:
            unknown.append(
                {
                    **row,
                    "status": "unknown",
                    "message": "No matching product in nearby inventory",
                }
            )
            continue
        qty = int(row["qty"]) if float(row["qty"]).is_integer() else row["qty"]
        if isinstance(qty, float):
            qty = max(1, int(round(qty)))
        else:
            qty = max(1, int(qty))
        matched.append(
            {
                "raw": row["raw"],
                "status": "matched",
                "name": product.name,
                "qty": qty,
                "unit": row.get("unit") or "",
                "product_id": str(product.id),
                "sku": product.sku,
                "price_minor": product.price_minor,
                "line_total_minor": product.price_minor * qty,
                "currency": product.currency,
                "store_id": str(product.store_id),
                "store_name": product.store.name,
                "stock_qty": product.stock_qty,
                "alternatives": alts,
                "notes": "",
            }
        )

    subtotal = sum(m["line_total_minor"] for m in matched)
    return {
        "source": "smart_shopping_list",
        "line_count": len(parsed_rows),
        "matched": matched,
        "unknown": unknown,
        "items": [{"name": m["name"], "qty": m["qty"], "product_id": m["product_id"]} for m in matched],
        "subtotal_minor": subtotal,
        "currency": "TZS",
        "preferred_store": ranking[0] if ranking else None,
        "ranking": ranking[:5],
        "templates_hint": ["breakfast", "weekly groceries", "cleaning", "baby"],
    }
