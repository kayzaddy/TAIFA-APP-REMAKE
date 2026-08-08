from __future__ import annotations

from typing import Protocol
from uuid import UUID

from taifa_merchant.infrastructure.models import (
    AuditLog,
    Branch,
    Device,
    Employee,
    Merchant,
    MerchantIdentityUser,
    MerchantProfile,
)


class MerchantRepository(Protocol):
    def get_by_id(self, merchant_id: UUID) -> Merchant | None: ...

    def get_for_user(self, identity_user_id: UUID) -> Merchant | None: ...

    def save(self, merchant: Merchant) -> Merchant: ...


class BranchRepository(Protocol):
    def list_for_merchant(self, merchant_id: UUID, *, include_inactive: bool = False) -> list[Branch]: ...

    def get_by_id(self, branch_id: UUID, merchant_id: UUID) -> Branch | None: ...

    def save(self, branch: Branch) -> Branch: ...


class EmployeeRepository(Protocol):
    def list_for_merchant(self, merchant_id: UUID) -> list[Employee]: ...

    def get_by_id(self, employee_id: UUID, merchant_id: UUID) -> Employee | None: ...

    def get_by_identity(self, merchant_id: UUID, identity_user_id: UUID) -> Employee | None: ...

    def save(self, employee: Employee) -> Employee: ...


class DeviceRepository(Protocol):
    def list_for_merchant(self, merchant_id: UUID) -> list[Device]: ...

    def get_by_id(self, device_id: UUID, merchant_id: UUID) -> Device | None: ...

    def save(self, device: Device) -> Device: ...


class AuditLogRepository(Protocol):
    def append(self, entry: AuditLog) -> AuditLog: ...


class IdentityUserRepository(Protocol):
    def get_by_email(self, email: str) -> MerchantIdentityUser | None: ...

    def get_by_id(self, user_id: UUID) -> MerchantIdentityUser | None: ...

    def save(self, user: MerchantIdentityUser) -> MerchantIdentityUser: ...
