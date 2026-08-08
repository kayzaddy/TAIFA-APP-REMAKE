from __future__ import annotations

from django.db import models


class MerchantStatus(models.TextChoices):
    DRAFT = "draft", "Draft"
    PENDING_VERIFICATION = "pending_verification", "Pending verification"
    VERIFIED = "verified", "Verified"
    SUSPENDED = "suspended", "Suspended"
    CLOSED = "closed", "Closed"


class VerificationStatus(models.TextChoices):
    NOT_STARTED = "not_started", "Not started"
    IN_REVIEW = "in_review", "In review"
    APPROVED = "approved", "Approved"
    REJECTED = "rejected", "Rejected"
    NEEDS_INFO = "needs_info", "Needs information"


class EmployeeRole(models.TextChoices):
    OWNER = "owner", "Owner"
    ADMINISTRATOR = "administrator", "Administrator"
    MANAGER = "manager", "Manager"
    CASHIER = "cashier", "Cashier"
    AUDITOR = "auditor", "Auditor"
    SUPPORT = "support", "Support"


class EmployeeStatus(models.TextChoices):
    INVITED = "invited", "Invited"
    ACTIVE = "active", "Active"
    SUSPENDED = "suspended", "Suspended"
    DEACTIVATED = "deactivated", "Deactivated"


class DeviceType(models.TextChoices):
    MOBILE = "mobile", "Mobile"
    TABLET = "tablet", "Tablet"
    ANDROID_PHONE = "android_phone", "Android phone"
    ANDROID_TABLET = "android_tablet", "Android tablet"
    POS = "pos", "POS terminal"
    DESKTOP_TERMINAL = "desktop_terminal", "Desktop terminal"
    OTHER = "other", "Other"


class DeviceStatus(models.TextChoices):
    PENDING = "pending", "Pending"
    ACTIVE = "active", "Active"
    DEACTIVATED = "deactivated", "Deactivated"


class DeviceHealth(models.TextChoices):
    UNKNOWN = "unknown", "Unknown"
    HEALTHY = "healthy", "Healthy"
    DEGRADED = "degraded", "Degraded"
    OFFLINE = "offline", "Offline"


ROLE_PERMISSIONS: dict[str, frozenset[str]] = {
    EmployeeRole.OWNER: frozenset(
        {
            "merchant:read",
            "merchant:write",
            "branch:read",
            "branch:write",
            "employee:read",
            "employee:write",
            "device:read",
            "device:write",
            "dashboard:read",
            "audit:read",
            "settings:read",
            "settings:write",
            "notification:read",
            "notification:write",
            "payment:read",
            "payment:accept",
            "payment:refund",
        }
    ),
    EmployeeRole.ADMINISTRATOR: frozenset(
        {
            "merchant:read",
            "merchant:write",
            "branch:read",
            "branch:write",
            "employee:read",
            "employee:write",
            "device:read",
            "device:write",
            "dashboard:read",
            "settings:read",
            "settings:write",
            "notification:read",
            "notification:write",
            "payment:read",
            "payment:accept",
            "payment:refund",
        }
    ),
    EmployeeRole.MANAGER: frozenset(
        {
            "merchant:read",
            "branch:read",
            "branch:write",
            "employee:read",
            "device:read",
            "device:write",
            "dashboard:read",
            "payment:read",
            "payment:accept",
            "payment:refund",
        }
    ),
    EmployeeRole.CASHIER: frozenset(
        {
            "merchant:read",
            "branch:read",
            "device:read",
            "dashboard:read",
            "payment:read",
            "payment:accept",
        }
    ),
    EmployeeRole.AUDITOR: frozenset(
        {
            "merchant:read",
            "branch:read",
            "employee:read",
            "device:read",
            "audit:read",
            "payment:read",
        }
    ),
    EmployeeRole.SUPPORT: frozenset({"merchant:read", "dashboard:read"}),
}
