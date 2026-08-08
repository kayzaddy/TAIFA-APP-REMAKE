from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import Any
from uuid import UUID


@dataclass(frozen=True, slots=True)
class DomainEvent:
    name: str
    aggregate_id: UUID
    occurred_at: datetime
    payload: dict[str, Any]


@dataclass(frozen=True, slots=True)
class MerchantRegistered(DomainEvent):
    pass


@dataclass(frozen=True, slots=True)
class BranchCreated(DomainEvent):
    pass


@dataclass(frozen=True, slots=True)
class EmployeeInvited(DomainEvent):
    pass


@dataclass(frozen=True, slots=True)
class DeviceRegistered(DomainEvent):
    pass
