"""Responsible AI — safety filters, PII redaction, prompt injection guards."""
from __future__ import annotations

import re

INJECTION_PATTERNS = [
    re.compile(r"ignore\s+(all\s+)?(previous|prior)\s+instructions", re.I),
    re.compile(r"system\s*:\s*you\s+are\s+now", re.I),
    re.compile(r"reveal\s+(your\s+)?(system\s+)?prompt", re.I),
    re.compile(r"jailbreak", re.I),
    re.compile(r"bypass\s+(payment|ledger|security|compliance)", re.I),
]

PII_PATTERNS = [
    (re.compile(r"\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b", re.I), "[REDACTED_EMAIL]"),
    (re.compile(r"\b(?:\+?255|0)\d{8,9}\b"), "[REDACTED_PHONE]"),
    (re.compile(r"\b\d{10,16}\b"), "[REDACTED_ID]"),
]

FORBIDDEN_ACTIONS = [
    "post_ledger",
    "mint_money",
    "override_identity",
    "disable_audit",
    "skip_compliance",
]


class SafetyError(Exception):
    pass


def redact_pii(payload: dict) -> tuple[dict, bool]:
    redacted = False

    def scrub(value):
        nonlocal redacted
        if isinstance(value, str):
            out = value
            for pattern, repl in PII_PATTERNS:
                if pattern.search(out):
                    redacted = True
                    out = pattern.sub(repl, out)
            return out
        if isinstance(value, dict):
            return {k: scrub(v) for k, v in value.items()}
        if isinstance(value, list):
            return [scrub(v) for v in value]
        return value

    return scrub(payload), redacted


def detect_prompt_injection(payload: dict) -> list[str]:
    blob = str(payload)
    hits = []
    for pattern in INJECTION_PATTERNS:
        if pattern.search(blob):
            hits.append(pattern.pattern)
    return hits


def assert_no_forbidden_actions(payload: dict) -> None:
    action = str(payload.get("action") or payload.get("requested_action") or "").lower()
    for forbidden in FORBIDDEN_ACTIONS:
        if forbidden in action:
            raise SafetyError(f"forbidden AI action requested: {forbidden}")


class SafetyViolation(SafetyError):
    def __init__(self, message: str, *, kind: str, detail: dict | None = None):
        super().__init__(message)
        self.kind = kind
        self.detail = detail or {}


def apply_safety(
    *,
    principal: str,
    payload: dict,
    pii_policy: str = "redact",
) -> tuple[dict, dict]:
    """Return (safe_payload, safety_meta). May raise SafetyViolation.

    Does not write SafetyEvent rows — callers persist them outside atomic blocks
    so audit rows survive transaction rollback.
    """
    injections = detect_prompt_injection(payload)
    if injections:
        raise SafetyViolation(
            "prompt injection blocked",
            kind="injection",
            detail={"patterns": injections},
        )

    assert_no_forbidden_actions(payload)

    safe = payload
    pii_redacted = False
    if pii_policy == "deny":
        _, has_pii = redact_pii(payload)
        if has_pii:
            raise SafetyViolation(
                "payload contains PII under deny policy",
                kind="pii",
                detail={"policy": "deny"},
            )
    elif pii_policy == "redact":
        safe, pii_redacted = redact_pii(payload)

    return safe, {
        "pii_redacted": pii_redacted,
        "injection_blocked": False,
        "policy": pii_policy,
    }
