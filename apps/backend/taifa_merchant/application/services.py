from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from uuid import UUID, uuid4

from django.db import transaction

from taifa_merchant.domain.enums import (
    DeviceHealth,
    DeviceStatus,
    EmployeeRole,
    EmployeeStatus,
    MerchantStatus,
    VerificationStatus,
)
from taifa_merchant.domain.events import BranchCreated, DeviceRegistered, DomainEvent, EmployeeInvited, MerchantRegistered
from taifa_merchant.infrastructure.events.dispatcher import dispatch
from taifa_merchant.infrastructure.identity.jwt_tokens import (
    issue_access_token,
    set_password,
    verify_password,
)
from taifa_merchant.infrastructure.models import (
    Branch,
    Device,
    Employee,
    Merchant,
    MerchantIdentityUser,
    MerchantProfile,
)
from taifa_merchant.infrastructure.workspace_defaults import ensure_merchant_workspace_defaults, refresh_branch_statistics
from taifa_merchant.infrastructure.tnpi.adapter import DevTnpiMerchantAdapter


class MerchantAppError(Exception):
    def __init__(self, message: str, code: str = "invalid_request", status: int = 400):
        super().__init__(message)
        self.code = code
        self.status = status


@dataclass
class AuthSession:
    access_token: str
    token_type: str = "Bearer"
    expires_in: int = 3600
    merchant_id: UUID | None = None
    roles: list[str] | None = None
    mfa_required: bool = False


class AuthService:
    def signup(self, *, email: str, password: str, full_name: str = "") -> AuthSession:
        email_norm = email.strip().lower()
        if MerchantIdentityUser.objects.filter(email=email_norm).exists():
            raise MerchantAppError("Email already registered", "email_exists", 409)
        user = MerchantIdentityUser(email=email_norm, full_name=full_name.strip())
        set_password(user, password)
        user.save()
        token = issue_access_token(user_id=user.id, email=user.email, merchant_id=None, roles=[])
        return AuthSession(access_token=token, merchant_id=None, roles=[])

    def login(self, *, email: str, password: str) -> AuthSession:
        email_norm = email.strip().lower()
        try:
            user = MerchantIdentityUser.objects.get(email=email_norm, is_active=True)
        except MerchantIdentityUser.DoesNotExist:
            raise MerchantAppError("Invalid credentials", "invalid_credentials", 401)
        if not verify_password(user, password):
            raise MerchantAppError("Invalid credentials", "invalid_credentials", 401)
        merchant_id, roles = self._resolve_merchant_context(user.id)
        if user.mfa_enabled:
            return AuthSession(
                access_token="",
                merchant_id=merchant_id,
                roles=roles,
                mfa_required=True,
            )
        token = issue_access_token(
            user_id=user.id,
            email=user.email,
            merchant_id=merchant_id,
            roles=roles,
            mfa_verified=True,
        )
        return AuthSession(access_token=token, merchant_id=merchant_id, roles=roles)

    def complete_mfa_login(self, *, email: str, password: str, _mfa_code: str) -> AuthSession:
        """Placeholder: accepts any code when MFA enabled in dev."""
        session = self.login(email=email, password=password)
        if not session.mfa_required:
            return session
        user = MerchantIdentityUser.objects.get(email=email.strip().lower())
        merchant_id, roles = self._resolve_merchant_context(user.id)
        token = issue_access_token(
            user_id=user.id,
            email=user.email,
            merchant_id=merchant_id,
            roles=roles,
            mfa_verified=True,
        )
        return AuthSession(access_token=token, merchant_id=merchant_id, roles=roles)

    def forgot_password(self, *, email: str) -> None:
        # Identity handles delivery in production; no user enumeration.
        if MerchantIdentityUser.objects.filter(email=email.strip().lower()).exists():
            pass

    def _resolve_merchant_context(self, user_id: UUID) -> tuple[UUID | None, list[str]]:
        employee = (
            Employee.objects.filter(identity_user_id=user_id, status=EmployeeStatus.ACTIVE)
            .select_related("merchant")
            .first()
        )
        if employee is None:
            merchant = Merchant.objects.filter(owner_identity_user_id=user_id).first()
            if merchant:
                return merchant.id, [EmployeeRole.OWNER]
            return None, []
        return employee.merchant_id, [employee.role]


class MerchantRegistrationService:
    def __init__(self, tnpi: DevTnpiMerchantAdapter | None = None) -> None:
        self._tnpi = tnpi or DevTnpiMerchantAdapter()

    @transaction.atomic
    def register_business(
        self,
        *,
        owner_user_id: UUID,
        legal_name: str,
        trading_name: str = "",
        business_category: str = "",
        tin: str = "",
        address_line1: str = "",
        city: str = "",
        region: str = "",
        contact_email: str = "",
        contact_phone: str = "",
    ) -> Merchant:
        if Merchant.objects.filter(owner_identity_user_id=owner_user_id).exists():
            raise MerchantAppError("Merchant already registered for this user", "merchant_exists", 409)
        merchant = Merchant.objects.create(
            legal_name=legal_name.strip(),
            trading_name=trading_name.strip() or legal_name.strip(),
            owner_identity_user_id=owner_user_id,
            status=MerchantStatus.PENDING_VERIFICATION,
            verification_status=VerificationStatus.IN_REVIEW,
        )
        MerchantProfile.objects.create(
            merchant=merchant,
            business_category=business_category,
            tin=tin,
            address_line1=address_line1,
            city=city,
            region=region,
            contact_email=contact_email or "",
            contact_phone=contact_phone,
        )
        Employee.objects.create(
            merchant=merchant,
            identity_user_id=owner_user_id,
            email=MerchantIdentityUser.objects.get(pk=owner_user_id).email,
            full_name=MerchantIdentityUser.objects.get(pk=owner_user_id).full_name,
            role=EmployeeRole.OWNER,
            status=EmployeeStatus.ACTIVE,
            activated_at=datetime.now(timezone.utc),
        )
        merchant.tnpi_merchant_id = self._tnpi.register_merchant(merchant)
        merchant.save(update_fields=["tnpi_merchant_id", "updated_at"])
        ensure_merchant_workspace_defaults(merchant.id)
        dispatch(
            MerchantRegistered(
                name="merchant.registered",
                aggregate_id=merchant.id,
                occurred_at=datetime.now(timezone.utc),
                payload={"merchant_id": str(merchant.id), "actor_id": str(owner_user_id), "resource_type": "merchant"},
            )
        )
        return merchant


class BranchService:
    @transaction.atomic
    def create(
        self,
        *,
        merchant_id: UUID,
        actor_id: UUID,
        name: str,
        code: str,
        address_line1: str = "",
        city: str = "",
        contact_phone: str = "",
        manager_employee_id: UUID | None = None,
        operating_hours: dict | None = None,
    ) -> Branch:
        branch = Branch.objects.create(
            merchant_id=merchant_id,
            name=name.strip(),
            code=code.strip().lower(),
            address_line1=address_line1,
            city=city,
            contact_phone=contact_phone,
            manager_employee_id=manager_employee_id,
            operating_hours=operating_hours or {},
        )
        dispatch(
            BranchCreated(
                name="branch.created",
                aggregate_id=branch.id,
                occurred_at=datetime.now(timezone.utc),
                payload={
                    "merchant_id": str(merchant_id),
                    "actor_id": str(actor_id),
                    "resource_type": "branch",
                },
            )
        )
        refresh_branch_statistics(branch.id)
        return branch

    def update(self, branch: Branch, **fields) -> Branch:
        for key, value in fields.items():
            if value is not None and hasattr(branch, key):
                setattr(branch, key, value)
        branch.save()
        return branch

    def deactivate(self, branch: Branch) -> Branch:
        branch.is_active = False
        branch.save(update_fields=["is_active", "updated_at"])
        return branch


class EmployeeService:
    @transaction.atomic
    def invite(
        self,
        *,
        merchant_id: UUID,
        actor_id: UUID,
        email: str,
        full_name: str,
        role: str,
    ) -> Employee:
        if role == EmployeeRole.OWNER:
            raise MerchantAppError("Cannot invite another owner", "invalid_role", 400)
        employee, created = Employee.objects.get_or_create(
            merchant_id=merchant_id,
            email=email.strip().lower(),
            defaults={
                "full_name": full_name.strip(),
                "role": role,
                "status": EmployeeStatus.INVITED,
            },
        )
        if not created:
            raise MerchantAppError("Employee already exists", "employee_exists", 409)
        dispatch(
            EmployeeInvited(
                name="employee.invited",
                aggregate_id=employee.id,
                occurred_at=datetime.now(timezone.utc),
                payload={
                    "merchant_id": str(merchant_id),
                    "actor_id": str(actor_id),
                    "resource_type": "employee",
                },
            )
        )
        return employee

    def assign_role(self, employee: Employee, role: str) -> Employee:
        if role == EmployeeRole.OWNER:
            raise MerchantAppError("Use ownership transfer for owner role", "invalid_role", 400)
        employee.role = role
        employee.save(update_fields=["role", "updated_at"])
        return employee

    def deactivate(self, employee: Employee) -> Employee:
        employee.status = EmployeeStatus.DEACTIVATED
        employee.deactivated_at = datetime.now(timezone.utc)
        employee.save(update_fields=["status", "deactivated_at", "updated_at"])
        return employee

    def activate_invite(self, *, employee: Employee, identity_user_id: UUID) -> Employee:
        employee.identity_user_id = identity_user_id
        employee.status = EmployeeStatus.ACTIVE
        employee.activated_at = datetime.now(timezone.utc)
        employee.save(update_fields=["identity_user_id", "status", "activated_at", "updated_at"])
        return employee


class DeviceService:
    @transaction.atomic
    def register(
        self,
        *,
        merchant_id: UUID,
        actor_employee_id: UUID | None,
        name: str,
        device_type: str,
        branch_id: UUID | None = None,
        hardware_fingerprint: str = "",
    ) -> Device:
        device = Device.objects.create(
            merchant_id=merchant_id,
            branch_id=branch_id,
            name=name.strip(),
            device_type=device_type,
            status=DeviceStatus.PENDING,
            health=DeviceHealth.UNKNOWN,
            hardware_fingerprint=hardware_fingerprint,
            registered_by_employee_id=actor_employee_id,
        )
        device.tnpi_device_id = f"dev-{device.id.hex[:12]}"
        device.save(update_fields=["tnpi_device_id", "updated_at"])
        dispatch(
            DeviceRegistered(
                name="device.registered",
                aggregate_id=device.id,
                occurred_at=datetime.now(timezone.utc),
                payload={
                    "merchant_id": str(merchant_id),
                    "actor_id": str(actor_employee_id) if actor_employee_id else None,
                    "resource_type": "device",
                },
            )
        )
        return device

    def activate(self, device: Device) -> Device:
        device.status = DeviceStatus.ACTIVE
        device.health = DeviceHealth.HEALTHY
        device.last_seen_at = datetime.now(timezone.utc)
        device.save(update_fields=["status", "health", "last_seen_at", "updated_at"])
        return device

    def deactivate(self, device: Device) -> Device:
        device.status = DeviceStatus.DEACTIVATED
        device.save(update_fields=["status", "updated_at"])
        return device


class DashboardService:
    def build(self, merchant_id: UUID) -> dict:
        from taifa_merchant.application.workspace_services import OperationalDashboardService

        return OperationalDashboardService().build(merchant_id)
