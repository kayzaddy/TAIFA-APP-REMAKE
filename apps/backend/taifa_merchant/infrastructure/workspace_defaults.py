from __future__ import annotations

from uuid import UUID

from taifa_merchant.infrastructure.models import (
    Branch,
    BranchStatistics,
    Device,
    Employee,
    EmployeePermission,
    EmployeeStatus,
    Merchant,
    MerchantNotification,
    MerchantSettings,
    NotificationPreference,
)


def ensure_merchant_workspace_defaults(merchant_id: UUID) -> None:
    MerchantSettings.objects.get_or_create(
        merchant_id=merchant_id,
        defaults={
            "payment_preferences": {
                "acceptance_enabled": False,
                "preferred_rails": [],
                "sprint3_ready": False,
            },
            "receipt_branding": {
                "footer_text": "Thank you for your business",
                "show_logo": True,
            },
            "tax_settings": {"vat_registered": False, "vat_rate": None},
        },
    )
    NotificationPreference.objects.get_or_create(merchant_id=merchant_id)
    merchant = Merchant.objects.get(pk=merchant_id)
    if not MerchantNotification.objects.filter(merchant_id=merchant_id).exists():
        MerchantNotification.objects.create(
            merchant=merchant,
            category="verification",
            title="Verification in progress",
            body="Complete your business profile to prepare for payment acceptance.",
        )


def refresh_branch_statistics(branch_id: UUID) -> None:
    branch = Branch.objects.get(pk=branch_id)
    employee_count = Employee.objects.filter(
        merchant_id=branch.merchant_id,
        status=EmployeeStatus.ACTIVE,
    ).count()
    device_count = Device.objects.filter(branch_id=branch_id).exclude(status="deactivated").count()
    stats, _ = BranchStatistics.objects.get_or_create(branch=branch)
    stats.employee_count = employee_count
    stats.device_count = device_count
    stats.save(update_fields=["employee_count", "device_count", "updated_at"])


def ensure_employee_permissions(employee: Employee) -> EmployeePermission:
    perms, _ = EmployeePermission.objects.get_or_create(employee=employee)
    return perms
