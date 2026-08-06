from __future__ import annotations

from datetime import datetime, timezone
from uuid import UUID

from django.db import transaction

from taifa_merchant.application.services import MerchantAppError
from taifa_merchant.domain.enums import DeviceStatus, EmployeeRole, EmployeeStatus, MerchantStatus, VerificationStatus
from taifa_merchant.infrastructure.models import (
    AuditLog,
    Branch,
    BranchStatistics,
    Device,
    DeviceAssignment,
    Employee,
    Merchant,
    MerchantActivity,
    MerchantNotification,
    MerchantProfile,
    MerchantSettings,
    NotificationPreference,
)
from taifa_merchant.infrastructure.workspace_defaults import (
    ensure_merchant_workspace_defaults,
    refresh_branch_statistics,
)


def record_activity(
    *,
    merchant_id: UUID,
    activity_type: str,
    summary: str,
    actor_id: UUID | None = None,
    branch_id: UUID | None = None,
    metadata: dict | None = None,
) -> MerchantActivity:
    return MerchantActivity.objects.create(
        merchant_id=merchant_id,
        branch_id=branch_id,
        actor_identity_user_id=actor_id,
        activity_type=activity_type,
        summary=summary,
        metadata=metadata or {},
    )


class BusinessProfileService:
    def get(self, merchant_id: UUID) -> tuple[Merchant, MerchantProfile]:
        merchant = Merchant.objects.select_related("profile").get(pk=merchant_id)
        profile, _ = MerchantProfile.objects.get_or_create(merchant=merchant)
        return merchant, profile

    @transaction.atomic
    def update(self, merchant_id: UUID, actor_id: UUID, **fields) -> Merchant:
        merchant, profile = self.get(merchant_id)
        merchant_fields = ("legal_name", "trading_name")
        for key in merchant_fields:
            if key in fields and fields[key] is not None:
                setattr(merchant, key, fields[key])
        merchant.save()
        profile_fields = (
            "description",
            "business_category",
            "tin",
            "address_line1",
            "address_line2",
            "city",
            "region",
            "country",
            "contact_email",
            "contact_phone",
            "operating_hours",
            "documents",
            "logo_s3_key",
        )
        for key in profile_fields:
            if key in fields and fields[key] is not None:
                setattr(profile, key, fields[key])
        profile.save()
        record_activity(
            merchant_id=merchant_id,
            actor_id=actor_id,
            activity_type="profile.updated",
            summary="Business profile updated",
        )
        return merchant


class MerchantSettingsService:
    def get_or_create(self, merchant_id: UUID) -> MerchantSettings:
        ensure_merchant_workspace_defaults(merchant_id)
        return MerchantSettings.objects.get(merchant_id=merchant_id)

    @transaction.atomic
    def update(self, merchant_id: UUID, actor_id: UUID, **fields) -> MerchantSettings:
        settings = self.get_or_create(merchant_id)
        for key in (
            "language",
            "currency",
            "timezone",
            "business_preferences",
            "payment_preferences",
            "receipt_branding",
            "tax_settings",
            "regional_settings",
        ):
            if key in fields and fields[key] is not None:
                setattr(settings, key, fields[key])
        settings.save()
        record_activity(
            merchant_id=merchant_id,
            actor_id=actor_id,
            activity_type="settings.updated",
            summary="Merchant settings updated",
        )
        return settings


class NotificationService:
    def list_notifications(self, merchant_id: UUID, *, unread_only: bool = False, limit: int = 50) -> list[MerchantNotification]:
        ensure_merchant_workspace_defaults(merchant_id)
        qs = MerchantNotification.objects.filter(merchant_id=merchant_id).order_by("-created_at")
        if unread_only:
            qs = qs.filter(is_read=False)
        return list(qs[:limit])

    def get_preferences(self, merchant_id: UUID) -> NotificationPreference:
        ensure_merchant_workspace_defaults(merchant_id)
        return NotificationPreference.objects.get(merchant_id=merchant_id)

    @transaction.atomic
    def update_preferences(self, merchant_id: UUID, actor_id: UUID, **fields) -> NotificationPreference:
        prefs = self.get_preferences(merchant_id)
        for key in (
            "push_enabled",
            "email_enabled",
            "sms_enabled",
            "system_alerts",
            "merchant_announcements",
            "device_alerts",
            "verification_alerts",
            "channels",
        ):
            if key in fields and fields[key] is not None:
                setattr(prefs, key, fields[key])
        prefs.save()
        record_activity(
            merchant_id=merchant_id,
            actor_id=actor_id,
            activity_type="notifications.preferences_updated",
            summary="Notification preferences updated",
        )
        return prefs

    def mark_read(self, merchant_id: UUID, notification_id: UUID) -> MerchantNotification:
        note = MerchantNotification.objects.filter(pk=notification_id, merchant_id=merchant_id).first()
        if note is None:
            raise MerchantAppError("Notification not found", "not_found", 404)
        note.is_read = True
        note.save(update_fields=["is_read"])
        return note


class BranchWorkspaceService:
    def dashboard(self, merchant_id: UUID, branch_id: UUID) -> dict:
        branch = Branch.objects.filter(pk=branch_id, merchant_id=merchant_id).select_related("statistics").first()
        if branch is None:
            raise MerchantAppError("Branch not found", "not_found", 404)
        refresh_branch_statistics(branch_id)
        stats = BranchStatistics.objects.filter(branch_id=branch_id).first()
        activities = MerchantActivity.objects.filter(merchant_id=merchant_id, branch_id=branch_id).order_by(
            "-created_at"
        )[:20]
        return {
            "branch": branch,
            "statistics": stats,
            "activities": activities,
        }


class EmployeeWorkspaceService:
    @transaction.atomic
    def suspend(self, employee: Employee, actor_id: UUID) -> Employee:
        if employee.role == EmployeeRole.OWNER:
            raise MerchantAppError("Cannot suspend owner", "invalid_operation", 400)
        employee.status = EmployeeStatus.SUSPENDED
        employee.save(update_fields=["status", "updated_at"])
        record_activity(
            merchant_id=employee.merchant_id,
            actor_id=actor_id,
            activity_type="employee.suspended",
            summary=f"Employee {employee.email} suspended",
            metadata={"employee_id": str(employee.id)},
        )
        return employee


class DeviceWorkspaceService:
    @transaction.atomic
    def assign(
        self,
        *,
        device: Device,
        actor_id: UUID,
        branch_id: UUID | None = None,
        assigned_employee_id: UUID | None = None,
    ) -> DeviceAssignment:
        DeviceAssignment.objects.filter(device=device, is_active=True).update(is_active=False)
        assignment = DeviceAssignment.objects.create(
            device=device,
            branch_id=branch_id or device.branch_id,
            assigned_employee_id=assigned_employee_id,
            assigned_by_identity_user_id=actor_id,
            is_active=True,
        )
        if branch_id:
            device.branch_id = branch_id
            device.save(update_fields=["branch_id", "updated_at"])
        record_activity(
            merchant_id=device.merchant_id,
            actor_id=actor_id,
            branch_id=assignment.branch_id,
            activity_type="device.assigned",
            summary=f"Device {device.name} assigned",
            metadata={"device_id": str(device.id)},
        )
        if device.branch_id:
            refresh_branch_statistics(device.branch_id)
        return assignment


class OperationalDashboardService:
    def build(self, merchant_id: UUID) -> dict:
        ensure_merchant_workspace_defaults(merchant_id)
        merchant = Merchant.objects.select_related("profile", "settings").get(pk=merchant_id)
        profile = getattr(merchant, "profile", None)
        settings = getattr(merchant, "settings", None)
        branches = Branch.objects.filter(merchant_id=merchant_id, is_active=True)
        branch_count = branches.count()
        employee_count = Employee.objects.filter(merchant_id=merchant_id, status=EmployeeStatus.ACTIVE).count()
        device_count = Device.objects.filter(merchant_id=merchant_id).exclude(status=DeviceStatus.DEACTIVATED).count()
        notifications = NotificationService().list_notifications(merchant_id, unread_only=True, limit=10)
        activities = MerchantActivity.objects.filter(merchant_id=merchant_id).order_by("-created_at")[:15]
        audit_tail = AuditLog.objects.filter(merchant_id=merchant_id).order_by("-created_at")[:10]
        pending_tasks = self._pending_tasks(merchant, profile, branch_count, device_count)
        health = self._merchant_health(merchant)
        return {
            "merchant": merchant,
            "profile": profile,
            "settings": settings,
            "counts": {
                "branches": branch_count,
                "employees": employee_count,
                "devices": device_count,
            },
            "merchant_health": health,
            "verification_progress": self._verification_progress(merchant),
            "branches_overview": list(branches[:5].values("id", "name", "code", "is_active")),
            "employees_overview": list(
                Employee.objects.filter(merchant_id=merchant_id)
                .order_by("-created_at")[:5]
                .values("id", "email", "full_name", "role", "status")
            ),
            "devices_overview": list(
                Device.objects.filter(merchant_id=merchant_id)
                .exclude(status=DeviceStatus.DEACTIVATED)
                .order_by("-created_at")[:5]
                .values("id", "name", "device_type", "status", "health", "branch_id")
            ),
            "notifications": notifications,
            "activity_timeline": activities,
            "audit_recent": audit_tail,
            "pending_tasks": pending_tasks,
            "system_status": {"api": "operational", "payments": "not_enabled", "identity": "dev_stub"},
            "quick_actions": [
                {"id": "edit_profile", "enabled": True, "route": "/taifa-merchant/profile"},
                {"id": "settings", "enabled": True, "route": "/taifa-merchant/settings"},
                {"id": "notifications", "enabled": True, "route": "/taifa-merchant/notifications"},
                {"id": "add_branch", "enabled": True, "route": "/taifa-merchant/branches"},
                {"id": "invite_employee", "enabled": True, "route": "/taifa-merchant/employees"},
                {"id": "register_device", "enabled": True, "route": "/taifa-merchant/devices"},
            ],
            "placeholders": {
                "payments": {"status": "coming_sprint_3", "label": "Payment acceptance"},
                "softpos": {"status": "coming_sprint_3", "label": "SoftPOS"},
                "qr": {"status": "coming_sprint_3", "label": "QR payments"},
                "payment_links": {"status": "coming_sprint_3", "label": "Payment links"},
                "analytics": {"status": "coming_sprint_3", "label": "Sales analytics"},
                "transactions": {"status": "coming_sprint_3", "label": "Transactions"},
            },
        }

    def _merchant_health(self, merchant: Merchant) -> str:
        if merchant.status == MerchantStatus.SUSPENDED:
            return "critical"
        if merchant.verification_status in (VerificationStatus.REJECTED, VerificationStatus.NEEDS_INFO):
            return "attention"
        if merchant.verification_status == VerificationStatus.APPROVED:
            return "healthy"
        return "warming_up"

    def _verification_progress(self, merchant: Merchant) -> dict:
        steps = [
            {
                "id": "business_profile",
                "complete": bool(
                    MerchantProfile.objects.filter(merchant_id=merchant.id, address_line1__gt="").exists()
                ),
            },
            {"id": "verification", "complete": merchant.verification_status == VerificationStatus.APPROVED},
            {"id": "branch", "complete": Branch.objects.filter(merchant_id=merchant.id, is_active=True).exists()},
            {"id": "device", "complete": Device.objects.filter(merchant_id=merchant.id, status=DeviceStatus.ACTIVE).exists()},
            {"id": "payment_prep", "complete": False},
        ]
        done = sum(1 for s in steps if s["complete"])
        return {"steps": steps, "percent": int(done / len(steps) * 100)}

    def _pending_tasks(self, merchant: Merchant, profile: MerchantProfile | None, branches: int, devices: int) -> list[dict]:
        tasks: list[dict] = []
        if profile and not profile.description:
            tasks.append({"id": "complete_description", "title": "Add business description"})
        if branches == 0:
            tasks.append({"id": "add_branch", "title": "Create your first branch"})
        if devices == 0:
            tasks.append({"id": "register_device", "title": "Register a device for acceptance prep"})
        if merchant.verification_status != VerificationStatus.APPROVED:
            tasks.append({"id": "verification", "title": "Complete merchant verification"})
        tasks.append({"id": "payment_preferences", "title": "Review payment preferences before Sprint 3"})
        return tasks
