"""Phone-based people lookup + saved contacts (the address book behind
"pay a friend"). No wallet identity here is human-findable otherwise — the
`owner` string (e.g. "dev_customer-juma-1") is an internal handle, not
something a real person ever sees or types.
"""
from __future__ import annotations

import re

_DIGITS = re.compile(r"[^\d+]")


def normalize_phone(raw: str) -> str:
    """Loose E.164-ish normalization: strip everything but digits, then
    ensure exactly one leading '+' — so "+255 754 000 891" and
    "255-754-000-891" compare equal.

    Not full libphonenumber validation. In particular this does NOT expand a
    local/trunk format like "0754000891" to a country code — that needs a
    default-region setting (e.g. device locale) this layer doesn't have.
    Callers should collect the number with an explicit country code.
    """
    cleaned = _DIGITS.sub("", raw.strip())
    digits = cleaned.lstrip("+")
    return f"+{digits}" if digits else ""
