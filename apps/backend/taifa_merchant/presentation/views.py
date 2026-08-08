from __future__ import annotations

from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from taifa_merchant.application.services import AuthService, MerchantAppError
from taifa_merchant.presentation.auth import (
    HasMerchantPermission,
    IsMerchantAuthenticated,
    MerchantJWTAuthentication,
    MerchantPrincipal,
    require_merchant_context,
)
from taifa_merchant.presentation.serializers import (
    AuthResponseSerializer,
    BranchCreateSerializer,
    BranchSerializer,
    DeviceRegisterSerializer,
    DeviceSerializer,
    EmployeeInviteSerializer,
    EmployeeRoleSerializer,
    EmployeeSerializer,
    ForgotPasswordSerializer,
    LoginSerializer,
    MerchantRegisterSerializer,
    MerchantSerializer,
    MerchantUpdateSerializer,
    MfaLoginSerializer,
    SignUpSerializer,
)
from taifa_merchant.application.services import (
    BranchService,
    DashboardService,
    DeviceService,
    EmployeeService,
    MerchantRegistrationService,
)
from taifa_merchant.infrastructure.models import Branch, Device, Employee, Merchant, MerchantProfile


def _session_response(session) -> Response:
    data = AuthResponseSerializer(
        {
            "access_token": session.access_token,
            "token_type": session.token_type,
            "expires_in": session.expires_in,
            "merchant_id": session.merchant_id,
            "roles": session.roles or [],
            "mfa_required": session.mfa_required,
        }
    ).data
    return Response(data)


def _handle_app_error(exc: MerchantAppError) -> Response:
    return Response({"code": exc.code, "detail": str(exc)}, status=exc.status)


class SignUpView(APIView):
    permission_classes = [AllowAny]
    authentication_classes: list = []

    def post(self, request):
        ser = SignUpSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        try:
            session = AuthService().signup(**ser.validated_data)
        except MerchantAppError as exc:
            return _handle_app_error(exc)
        return _session_response(session)


class LoginView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        ser = LoginSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        try:
            session = AuthService().login(**ser.validated_data)
        except MerchantAppError as exc:
            return _handle_app_error(exc)
        if session.mfa_required:
            return Response(
                AuthResponseSerializer(
                    {
                        "access_token": "",
                        "token_type": "Bearer",
                        "expires_in": 0,
                        "merchant_id": session.merchant_id,
                        "roles": session.roles or [],
                        "mfa_required": True,
                    }
                ).data,
                status=status.HTTP_200_OK,
            )
        return _session_response(session)


class MfaLoginView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        ser = MfaLoginSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        try:
            session = AuthService().complete_mfa_login(**ser.validated_data)
        except MerchantAppError as exc:
            return _handle_app_error(exc)
        return _session_response(session)


class ForgotPasswordView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        ser = ForgotPasswordSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        AuthService().forgot_password(**ser.validated_data)
        return Response(status=status.HTTP_202_ACCEPTED)


class LogoutView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated]

    def post(self, request):
        # Stateless JWT — client discards token; hook Identity revoke when integrated.
        return Response(status=status.HTTP_204_NO_CONTENT)


class SessionView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated]

    def get(self, request):
        user: MerchantPrincipal = request.user
        return Response(
            {
                "user_id": str(user.user_id),
                "email": user.email,
                "merchant_id": str(user.merchant_id) if user.merchant_id else None,
                "roles": user.roles,
            }
        )


class MerchantRegisterView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated]
    required_permission = "merchant:write"

    def post(self, request):
        user: MerchantPrincipal = request.user
        ser = MerchantRegisterSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        try:
            merchant = MerchantRegistrationService().register_business(
                owner_user_id=user.user_id,
                **ser.validated_data,
            )
        except MerchantAppError as exc:
            return _handle_app_error(exc)
        from taifa_merchant.infrastructure.identity.jwt_tokens import issue_access_token
        from taifa_merchant.domain.enums import EmployeeRole

        token = issue_access_token(
            user_id=user.user_id,
            email=user.email,
            merchant_id=merchant.id,
            roles=[EmployeeRole.OWNER],
        )
        return Response(
            {
                **MerchantSerializer(merchant).data,
                "access_token": token,
                "token_type": "Bearer",
            },
            status=status.HTTP_201_CREATED,
        )


class MerchantMeView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "merchant:read"

    def get(self, request):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        merchant = Merchant.objects.select_related("profile").get(pk=merchant_id)
        return Response(MerchantSerializer(merchant).data)

    def patch(self, request):
        user: MerchantPrincipal = request.user
        if not user.has_permission("merchant:write"):
            return Response(status=status.HTTP_403_FORBIDDEN)
        merchant_id = require_merchant_context(user)
        ser = MerchantUpdateSerializer(data=request.data, partial=True)
        ser.is_valid(raise_exception=True)
        merchant = Merchant.objects.select_related("profile").get(pk=merchant_id)
        data = ser.validated_data
        if "legal_name" in data:
            merchant.legal_name = data["legal_name"]
        if "trading_name" in data:
            merchant.trading_name = data["trading_name"]
        merchant.save()
        profile, _ = MerchantProfile.objects.get_or_create(merchant=merchant)
        for field in ("business_category", "tin", "address_line1", "city", "region", "contact_email", "contact_phone"):
            if field in data:
                setattr(profile, field, data[field])
        profile.save()
        merchant.refresh_from_db()
        return Response(MerchantSerializer(merchant).data)


class BranchListCreateView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "branch:read"

    def get(self, request):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        qs = Branch.objects.filter(merchant_id=merchant_id)
        if request.query_params.get("active_only", "true").lower() == "true":
            qs = qs.filter(is_active=True)
        return Response(BranchSerializer(qs.order_by("name"), many=True).data)

    def post(self, request):
        user: MerchantPrincipal = request.user
        if not user.has_permission("branch:write"):
            return Response(status=status.HTTP_403_FORBIDDEN)
        merchant_id = require_merchant_context(user)
        ser = BranchCreateSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        branch = BranchService().create(merchant_id=merchant_id, actor_id=user.user_id, **ser.validated_data)
        return Response(BranchSerializer(branch).data, status=status.HTTP_201_CREATED)


class BranchDetailView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "branch:read"

    @extend_schema(operation_id="merchant_app_branch_detail")
    def get(self, request, branch_id):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        branch = Branch.objects.filter(pk=branch_id, merchant_id=merchant_id).first()
        if branch is None:
            return Response(status=status.HTTP_404_NOT_FOUND)
        return Response(BranchSerializer(branch).data)

    def patch(self, request, branch_id):
        user: MerchantPrincipal = request.user
        if not user.has_permission("branch:write"):
            return Response(status=status.HTTP_403_FORBIDDEN)
        merchant_id = require_merchant_context(user)
        branch = Branch.objects.filter(pk=branch_id, merchant_id=merchant_id).first()
        if branch is None:
            return Response(status=status.HTTP_404_NOT_FOUND)
        ser = BranchCreateSerializer(data=request.data, partial=True)
        ser.is_valid(raise_exception=True)
        branch = BranchService().update(branch, **ser.validated_data)
        return Response(BranchSerializer(branch).data)

    def delete(self, request, branch_id):
        user: MerchantPrincipal = request.user
        if not user.has_permission("branch:write"):
            return Response(status=status.HTTP_403_FORBIDDEN)
        merchant_id = require_merchant_context(user)
        branch = Branch.objects.filter(pk=branch_id, merchant_id=merchant_id).first()
        if branch is None:
            return Response(status=status.HTTP_404_NOT_FOUND)
        BranchService().deactivate(branch)
        return Response(status=status.HTTP_204_NO_CONTENT)


class EmployeeListInviteView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "employee:read"

    def get(self, request):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        employees = Employee.objects.filter(merchant_id=merchant_id).order_by("-created_at")
        return Response(EmployeeSerializer(employees, many=True).data)

    def post(self, request):
        user: MerchantPrincipal = request.user
        if not user.has_permission("employee:write"):
            return Response(status=status.HTTP_403_FORBIDDEN)
        merchant_id = require_merchant_context(user)
        ser = EmployeeInviteSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        try:
            employee = EmployeeService().invite(
                merchant_id=merchant_id,
                actor_id=user.user_id,
                **ser.validated_data,
            )
        except MerchantAppError as exc:
            return _handle_app_error(exc)
        return Response(EmployeeSerializer(employee).data, status=status.HTTP_201_CREATED)


class EmployeeDetailView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "employee:read"

    def patch(self, request, employee_id):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        employee = Employee.objects.filter(pk=employee_id, merchant_id=merchant_id).first()
        if employee is None:
            return Response(status=status.HTTP_404_NOT_FOUND)
        if "role" in request.data:
            if not user.has_permission("employee:write"):
                return Response(status=status.HTTP_403_FORBIDDEN)
            ser = EmployeeRoleSerializer(data=request.data)
            ser.is_valid(raise_exception=True)
            employee = EmployeeService().assign_role(employee, ser.validated_data["role"])
        return Response(EmployeeSerializer(employee).data)

    def delete(self, request, employee_id):
        user: MerchantPrincipal = request.user
        if not user.has_permission("employee:write"):
            return Response(status=status.HTTP_403_FORBIDDEN)
        merchant_id = require_merchant_context(user)
        employee = Employee.objects.filter(pk=employee_id, merchant_id=merchant_id).first()
        if employee is None:
            return Response(status=status.HTTP_404_NOT_FOUND)
        EmployeeService().deactivate(employee)
        return Response(status=status.HTTP_204_NO_CONTENT)


class DeviceListCreateView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "device:read"

    def get(self, request):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        devices = Device.objects.filter(merchant_id=merchant_id).order_by("-created_at")
        return Response(DeviceSerializer(devices, many=True).data)

    def post(self, request):
        user: MerchantPrincipal = request.user
        if not user.has_permission("device:write"):
            return Response(status=status.HTTP_403_FORBIDDEN)
        merchant_id = require_merchant_context(user)
        ser = DeviceRegisterSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        from taifa_merchant.presentation.auth import current_employee

        emp = current_employee(user, merchant_id)
        device = DeviceService().register(
            merchant_id=merchant_id,
            actor_employee_id=emp.id if emp else None,
            **ser.validated_data,
        )
        return Response(DeviceSerializer(device).data, status=status.HTTP_201_CREATED)


class DeviceActivateView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "device:write"

    def post(self, request, device_id):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        device = Device.objects.filter(pk=device_id, merchant_id=merchant_id).first()
        if device is None:
            return Response(status=status.HTTP_404_NOT_FOUND)
        device = DeviceService().activate(device)
        return Response(DeviceSerializer(device).data)


class DeviceDeactivateView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "device:write"

    def post(self, request, device_id):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        device = Device.objects.filter(pk=device_id, merchant_id=merchant_id).first()
        if device is None:
            return Response(status=status.HTTP_404_NOT_FOUND)
        device = DeviceService().deactivate(device)
        return Response(DeviceSerializer(device).data)


class DashboardView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "dashboard:read"

    def get(self, request):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        payload = DashboardService().build(merchant_id)
        from taifa_merchant.presentation.workspace_views import serialize_dashboard_payload

        return Response(serialize_dashboard_payload(payload))
