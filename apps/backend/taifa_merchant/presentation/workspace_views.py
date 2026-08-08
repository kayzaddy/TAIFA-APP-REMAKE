from __future__ import annotations

from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from taifa_merchant.application.services import MerchantAppError
from taifa_merchant.application.workspace_services import (
    BranchWorkspaceService,
    BusinessProfileService,
    DeviceWorkspaceService,
    EmployeeWorkspaceService,
    NotificationService,
    OperationalDashboardService,
    record_activity,
)
from taifa_merchant.infrastructure.models import Device, Employee, MerchantActivity, MerchantNotification
from taifa_merchant.presentation.auth import (
    HasMerchantPermission,
    IsMerchantAuthenticated,
    MerchantJWTAuthentication,
    MerchantPrincipal,
    require_merchant_context,
)
from taifa_merchant.presentation.serializers import (
    BranchSerializer,
    BranchStatisticsSerializer,
    DeviceAssignSerializer,
    DeviceAssignmentSerializer,
    DeviceSerializer,
    EmployeeSerializer,
    MerchantNotificationSerializer,
    MerchantProfileSerializer,
    MerchantSerializer,
    MerchantSettingsSerializer,
    MerchantSettingsUpdateSerializer,
    MerchantUpdateSerializer,
    NotificationPreferenceSerializer,
)


def _handle_app_error(exc: MerchantAppError) -> Response:
    return Response({"code": exc.code, "detail": str(exc)}, status=exc.status)


def serialize_dashboard_payload(payload: dict) -> dict:
    merchant = payload["merchant"]
    profile = payload.get("profile")
    settings = payload.get("settings")
    placeholders = payload.get("placeholders") or {}
    legacy_placeholders = {k: v.get("status", "coming_soon") if isinstance(v, dict) else v for k, v in placeholders.items()}
    return {
        "merchant": MerchantSerializer(merchant).data,
        "business_status": merchant.status,
        "verification_status": merchant.verification_status,
        "merchant_health": payload.get("merchant_health"),
        "verification_progress": payload.get("verification_progress"),
        "counts": payload.get("counts"),
        "branches_summary": payload.get("counts", {}).get("branches"),
        "employees_summary": payload.get("counts", {}).get("employees"),
        "devices_summary": payload.get("counts", {}).get("devices"),
        "branches_overview": payload.get("branches_overview"),
        "employees_overview": payload.get("employees_overview"),
        "devices_overview": payload.get("devices_overview"),
        "notifications": MerchantNotificationSerializer(payload.get("notifications") or [], many=True).data,
        "activity_timeline": [
            {
                "id": str(a.id),
                "activity_type": a.activity_type,
                "summary": a.summary,
                "created_at": a.created_at.isoformat(),
                "metadata": a.metadata,
            }
            for a in payload.get("activity_timeline") or []
        ],
        "pending_tasks": payload.get("pending_tasks"),
        "system_status": payload.get("system_status"),
        "quick_actions": payload.get("quick_actions"),
        "placeholders": legacy_placeholders,
        "placeholders_detail": placeholders,
        "profile": MerchantProfileSerializer(profile).data if profile else None,
        "settings_summary": MerchantSettingsSerializer(settings).data if settings else None,
    }


class BusinessProfileView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "merchant:read"

    def get(self, request):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        merchant, profile = BusinessProfileService().get(merchant_id)
        return Response(
            {
                "merchant": MerchantSerializer(merchant).data,
                "verification_status": merchant.verification_status,
                "profile": MerchantProfileSerializer(profile).data,
            }
        )

    def patch(self, request):
        user: MerchantPrincipal = request.user
        if not user.has_permission("merchant:write"):
            return Response(status=status.HTTP_403_FORBIDDEN)
        merchant_id = require_merchant_context(user)
        ser = MerchantUpdateSerializer(data=request.data, partial=True)
        ser.is_valid(raise_exception=True)
        merchant = BusinessProfileService().update(merchant_id, user.user_id, **ser.validated_data)
        merchant, profile = BusinessProfileService().get(merchant_id)
        return Response(
            {
                "merchant": MerchantSerializer(merchant).data,
                "profile": MerchantProfileSerializer(profile).data,
            }
        )


class MerchantSettingsView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "settings:read"

    def get(self, request):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        from taifa_merchant.application.workspace_services import MerchantSettingsService

        settings = MerchantSettingsService().get_or_create(merchant_id)
        return Response(MerchantSettingsSerializer(settings).data)

    def patch(self, request):
        user: MerchantPrincipal = request.user
        if not user.has_permission("settings:write"):
            return Response(status=status.HTTP_403_FORBIDDEN)
        merchant_id = require_merchant_context(user)
        ser = MerchantSettingsUpdateSerializer(data=request.data, partial=True)
        ser.is_valid(raise_exception=True)
        from taifa_merchant.application.workspace_services import MerchantSettingsService

        settings = MerchantSettingsService().update(merchant_id, user.user_id, **ser.validated_data)
        return Response(MerchantSettingsSerializer(settings).data)


class NotificationListView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "notification:read"

    def get(self, request):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        unread = request.query_params.get("unread_only", "false").lower() == "true"
        notes = NotificationService().list_notifications(merchant_id, unread_only=unread)
        return Response(MerchantNotificationSerializer(notes, many=True).data)


class NotificationReadView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "notification:write"

    def post(self, request, notification_id):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        try:
            note = NotificationService().mark_read(merchant_id, notification_id)
        except MerchantAppError as exc:
            return _handle_app_error(exc)
        return Response(MerchantNotificationSerializer(note).data)


class NotificationPreferencesView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "notification:read"

    def get(self, request):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        prefs = NotificationService().get_preferences(merchant_id)
        return Response(NotificationPreferenceSerializer(prefs).data)

    def patch(self, request):
        user: MerchantPrincipal = request.user
        if not user.has_permission("notification:write"):
            return Response(status=status.HTTP_403_FORBIDDEN)
        merchant_id = require_merchant_context(user)
        ser = NotificationPreferenceSerializer(data=request.data, partial=True)
        ser.is_valid(raise_exception=True)
        prefs = NotificationService().update_preferences(merchant_id, user.user_id, **ser.validated_data)
        return Response(NotificationPreferenceSerializer(prefs).data)


class ActivityTimelineView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "dashboard:read"

    def get(self, request):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        qs = MerchantActivity.objects.filter(merchant_id=merchant_id).order_by("-created_at")[:50]
        return Response(
            [
                {
                    "id": str(a.id),
                    "activity_type": a.activity_type,
                    "summary": a.summary,
                    "branch_id": str(a.branch_id) if a.branch_id else None,
                    "created_at": a.created_at.isoformat(),
                    "metadata": a.metadata,
                }
                for a in qs
            ]
        )


class BranchDashboardView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "branch:read"

    def get(self, request, branch_id):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        try:
            data = BranchWorkspaceService().dashboard(merchant_id, branch_id)
        except MerchantAppError as exc:
            return _handle_app_error(exc)
        branch = data["branch"]
        stats = data["statistics"]
        return Response(
            {
                "branch": BranchSerializer(branch).data,
                "statistics": BranchStatisticsSerializer(stats).data if stats else None,
                "activities": [
                    {
                        "id": str(a.id),
                        "activity_type": a.activity_type,
                        "summary": a.summary,
                        "created_at": a.created_at.isoformat(),
                    }
                    for a in data["activities"]
                ],
            }
        )


class EmployeeSuspendView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "employee:write"

    def post(self, request, employee_id):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        employee = Employee.objects.filter(pk=employee_id, merchant_id=merchant_id).first()
        if employee is None:
            return Response(status=status.HTTP_404_NOT_FOUND)
        try:
            employee = EmployeeWorkspaceService().suspend(employee, user.user_id)
        except MerchantAppError as exc:
            return _handle_app_error(exc)
        return Response(EmployeeSerializer(employee).data)


class DeviceDetailView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "device:read"

    @extend_schema(operation_id="merchant_app_device_detail")
    def get(self, request, device_id):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        device = Device.objects.filter(pk=device_id, merchant_id=merchant_id).first()
        if device is None:
            return Response(status=status.HTTP_404_NOT_FOUND)
        assignment = device.assignments.filter(is_active=True).first()
        return Response(
            {
                "device": DeviceSerializer(device).data,
                "assignment": DeviceAssignmentSerializer(assignment).data if assignment else None,
            }
        )


class DeviceAssignView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "device:write"

    def post(self, request, device_id):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        device = Device.objects.filter(pk=device_id, merchant_id=merchant_id).first()
        if device is None:
            return Response(status=status.HTTP_404_NOT_FOUND)
        ser = DeviceAssignSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        assignment = DeviceWorkspaceService().assign(device=device, actor_id=user.user_id, **ser.validated_data)
        return Response(DeviceAssignmentSerializer(assignment).data, status=status.HTTP_201_CREATED)


class OperationalDashboardView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "dashboard:read"

    def get(self, request):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        payload = OperationalDashboardService().build(merchant_id)
        return Response(serialize_dashboard_payload(payload))
