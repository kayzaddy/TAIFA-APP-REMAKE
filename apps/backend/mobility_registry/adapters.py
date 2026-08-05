"""Provider-neutral government/authority verification contracts."""
from __future__ import annotations

from dataclasses import dataclass
from importlib import import_module
from typing import Protocol

from django.conf import settings


@dataclass(frozen=True)
class VerificationResult:
    provider_reference: str
    verified: bool
    status: str
    attributes: dict


class VerificationAdapter(Protocol):
    provider_code: str
    supported_checks: frozenset[str]

    def verify(
        self,
        *,
        check_type: str,
        subject_reference: str,
        attributes: dict,
    ) -> VerificationResult: ...


class AdapterNotConfigured(RuntimeError):
    pass


def adapter_for(provider: str) -> VerificationAdapter:
    path = (getattr(settings, "MOBILITY_VERIFICATION_ADAPTERS", {}) or {}).get(provider)
    if not path:
        raise AdapterNotConfigured(f"{provider} adapter is not configured")
    module_name, class_name = path.rsplit(".", 1)
    adapter = getattr(import_module(module_name), class_name)()
    if adapter.provider_code != provider:
        raise AdapterNotConfigured(f"{provider} adapter identity mismatch")
    return adapter
