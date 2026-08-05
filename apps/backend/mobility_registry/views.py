from __future__ import annotations

from django.db import IntegrityError, transaction
from django.db.models import Count, Q
from django.http import HttpResponse
from django.shortcuts import get_object_or_404
from django.utils import timezone
from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework import status
from rest_framework.exceptions import PermissionDenied
from rest_framework.pagination import PageNumberPagination
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView

from payments.auth import IsDevice

from .crypto import active_key_version, blind_index, encrypt_text, mask
from .models import (
    ApplicationStatus,
    ApplicationType,
    ComplianceFinding,
    DocumentStatus,
    DriverRegistration,
    FleetRegistration,
    RegistryApplication,
    RegistryDocument,
    RegistryNotification,
    StationRegistration,
    VehicleRegistration,
)
from .permissions import (
    has_registry_permission,
    may_access_region,
    request_owner,
)
from .serializers import (
    ApplicationSerializer,
    BlacklistCreateSerializer,
    BlacklistSerializer,
    ComplianceDashboardSerializer,
    DocumentDecisionSerializer,
    DocumentSerializer,
    DocumentUploadSerializer,
    DriverRegistrationSerializer,
    ExternalVerificationSerializer,
    FleetRegistrationSerializer,
    RegistrySearchResultSerializer,
    StationRegistrationSerializer,
    VehicleRegistrationSerializer,
    VerificationQueueSerializer,
    WorkflowActionSerializer,
    WorkflowTransitionSerializer,
)
from .services import (
    ActorContext,
    RegistryError,
    add_blacklist_entry,
    advance_stage,
    approve_application,
    create_application,
    decrypt_document,
    reject_application,
    request_external_verification,
    review_document,
    submit_application,
    suspend_application,
    upload_document,
)


class RegistryPagination(PageNumberPagination):
    page_size = 25
    page_size_query_param = "page_size"
    max_page_size = 100


def _actor(request) -> ActorContext:
    forwarded = request.META.get("HTTP_X_FORWARDED_FOR", "")
    ip = forwarded.split(",")[0].strip() if forwarded else request.META.get("REMOTE_ADDR")
    return ActorContext(
        principal=request_owner(request),
        ip_address=ip,
        device_id=request.META.get("HTTP_X_DEVICE_ID", ""),
    )


def _require(request, permission: str) -> None:
    if not has_registry_permission(request, permission):
        raise PermissionDenied(f"{permission} permission required")


def _accessible_application(request, application_id) -> RegistryApplication:
    application = get_object_or_404(RegistryApplication, pk=application_id)
    if application.applicant_principal == request_owner(request):
        return application
    if not has_registry_permission(request, "mobility_registry.application.read"):
        raise PermissionDenied("application access denied")
    if not may_access_region(request, application.region):
        raise PermissionDenied("application region access denied")
    return application


def _paginate(request, queryset, serializer_class):
    paginator = RegistryPagination()
    page = paginator.paginate_queryset(queryset, request)
    return paginator.get_paginated_response(serializer_class(page, many=True).data)


@extend_schema(tags=["mobility-registry"], responses=ApplicationSerializer(many=True))
class ApplicationListView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        queryset = RegistryApplication.objects.filter(
            applicant_principal=request_owner(request)
        ).order_by("-created_at")
        return _paginate(request, queryset, ApplicationSerializer)


@extend_schema(tags=["mobility-registry"], responses=ApplicationSerializer)
class ApplicationDetailView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, application_id):
        return Response(ApplicationSerializer(_accessible_application(request, application_id)).data)


@extend_schema(
    tags=["mobility-registry"],
    request=DriverRegistrationSerializer,
    responses={201: ApplicationSerializer},
)
class DriverRegistrationView(APIView):
    permission_classes = [IsDevice]

    @transaction.atomic
    def post(self, request):
        serializer = DriverRegistrationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        owner = request_owner(request)
        if data.get("wallet_account_ref") and data["wallet_account_ref"] != owner:
            return Response({"detail": "wallet account must belong to applicant"}, status=403)
        application = create_application(
            application_type=ApplicationType.DRIVER,
            applicant_principal=owner,
            client_reference=data["client_reference"],
            region=data["region"],
            district=data["district"],
            actor=_actor(request),
        )
        if hasattr(application, "driver"):
            return Response(ApplicationSerializer(application).data)
        try:
            national_id = encrypt_text(
                data["national_id_number"],
                context=f"registry-driver-national-id:{application.id}",
            )
            phone = encrypt_text(
                data["phone_number"],
                context=f"registry-driver-phone:{application.id}",
            )
            emergency = encrypt_text(
                data["emergency_contact_phone"],
                context=f"registry-driver-emergency-phone:{application.id}",
            )
            passport = (
                encrypt_text(
                    data["passport_number"],
                    context=f"registry-driver-passport:{application.id}",
                )
                if data.get("passport_number")
                else None
            )
            bank = (
                encrypt_text(
                    data["bank_account"],
                    context=f"registry-driver-bank:{application.id}",
                )
                if data.get("bank_account")
                else None
            )
            DriverRegistration.objects.create(
                application=application,
                full_name=data["full_name"],
                pii_key_version=active_key_version(),
                national_id_ciphertext=national_id.ciphertext,
                national_id_nonce=national_id.nonce,
                national_id_hash=blind_index(data["national_id_number"]),
                national_id_masked=mask(data["national_id_number"]),
                passport_ciphertext=passport.ciphertext if passport else None,
                passport_nonce=passport.nonce if passport else None,
                passport_hash=blind_index(data["passport_number"]) if passport else "",
                phone_ciphertext=phone.ciphertext,
                phone_nonce=phone.nonce,
                phone_hash=blind_index(data["phone_number"]),
                phone_masked=mask(data["phone_number"]),
                email=data.get("email", ""),
                gender=data["gender"],
                date_of_birth=data["date_of_birth"],
                nationality=data["nationality"],
                ward=data.get("ward", ""),
                street=data.get("street", ""),
                postal_address=data.get("postal_address", ""),
                emergency_contact_name=data["emergency_contact_name"],
                emergency_phone_ciphertext=emergency.ciphertext,
                emergency_phone_nonce=emergency.nonce,
                emergency_phone_masked=mask(data["emergency_contact_phone"]),
                preferred_station_id=data.get("preferred_station"),
                preferred_language=data["preferred_language"],
                bank_account_ciphertext=bank.ciphertext if bank else None,
                bank_account_nonce=bank.nonce if bank else None,
                wallet_account_ref=owner,
            )
        except IntegrityError:
            return Response({"detail": "identity is already registered"}, status=409)
        return Response(ApplicationSerializer(application).data, status=201)


@extend_schema(
    tags=["mobility-registry"],
    request=VehicleRegistrationSerializer,
    responses={201: ApplicationSerializer},
)
class VehicleRegistrationView(APIView):
    permission_classes = [IsDevice]

    @transaction.atomic
    def post(self, request):
        serializer = VehicleRegistrationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        owner = request_owner(request)
        owner_principal = data.get("owner_principal") or owner
        if owner_principal != owner:
            _require(request, "mobility_registry.fleet.manage")
        assigned = None
        if data.get("assigned_driver_application"):
            assigned = get_object_or_404(
                RegistryApplication,
                pk=data["assigned_driver_application"],
                application_type=ApplicationType.DRIVER,
                status=ApplicationStatus.APPROVED,
            )
        application = create_application(
            application_type=ApplicationType.VEHICLE,
            applicant_principal=owner,
            client_reference=data["client_reference"],
            region=data["region"],
            district=data["district"],
            actor=_actor(request),
        )
        if hasattr(application, "vehicle"):
            return Response(ApplicationSerializer(application).data)
        chassis = encrypt_text(
            data["chassis_number"],
            context=f"registry-vehicle-chassis:{application.id}",
        )
        engine = encrypt_text(
            data["engine_number"],
            context=f"registry-vehicle-engine:{application.id}",
        )
        try:
            VehicleRegistration.objects.create(
                application=application,
                pii_key_version=active_key_version(),
                mode=data["mode"],
                registration_number=data["registration_number"].upper().replace(" ", ""),
                registration_number_hash=blind_index(data["registration_number"]),
                chassis_number_hash=blind_index(data["chassis_number"]),
                chassis_number_ciphertext=chassis.ciphertext,
                chassis_number_nonce=chassis.nonce,
                engine_number_hash=blind_index(data["engine_number"]),
                engine_number_ciphertext=engine.ciphertext,
                engine_number_nonce=engine.nonce,
                make=data["make"],
                model=data["model"],
                year=data["year"],
                fuel_type=data["fuel_type"],
                color=data["color"],
                capacity=data["capacity"],
                owner_principal=owner_principal,
                assigned_driver_application=assigned,
            )
        except IntegrityError:
            return Response({"detail": "vehicle identifiers are already registered"}, status=409)
        return Response(ApplicationSerializer(application).data, status=201)


@extend_schema(
    tags=["mobility-registry"],
    request=StationRegistrationSerializer,
    responses={201: ApplicationSerializer},
)
class StationRegistrationView(APIView):
    permission_classes = [IsDevice]

    @transaction.atomic
    def post(self, request):
        serializer = StationRegistrationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        owner = request_owner(request)
        manager = data.get("manager_principal") or owner
        if manager != owner:
            _require(request, "mobility_registry.station.manage")
        application = create_application(
            application_type=ApplicationType.STATION,
            applicant_principal=owner,
            client_reference=data["client_reference"],
            region=data["region"],
            district=data["district"],
            actor=_actor(request),
        )
        if hasattr(application, "station"):
            return Response(ApplicationSerializer(application).data)
        phone = encrypt_text(
            data["phone_number"],
            context=f"registry-station-phone:{application.id}",
        )
        try:
            StationRegistration.objects.create(
                application=application,
                pii_key_version=active_key_version(),
                name=data["name"],
                code=data["code"],
                latitude=data["latitude"],
                longitude=data["longitude"],
                ward=data["ward"],
                street=data["street"],
                manager_principal=manager,
                phone_ciphertext=phone.ciphertext,
                phone_nonce=phone.nonce,
                phone_hash=blind_index(data["phone_number"]),
                phone_masked=mask(data["phone_number"]),
                email=data.get("email", ""),
                operating_hours=data["operating_hours"],
                capacity=data["capacity"],
                description=data.get("description", ""),
            )
        except IntegrityError:
            return Response({"detail": "station code is already registered"}, status=409)
        return Response(ApplicationSerializer(application).data, status=201)


@extend_schema(
    tags=["mobility-registry"],
    request=FleetRegistrationSerializer,
    responses={201: ApplicationSerializer},
)
class FleetRegistrationView(APIView):
    permission_classes = [IsDevice]

    @transaction.atomic
    def post(self, request):
        serializer = FleetRegistrationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        owner = request_owner(request)
        owner_principal = data.get("owner_principal") or owner
        if owner_principal != owner:
            _require(request, "mobility_registry.fleet.manage")
        if data.get("settlement_wallet_ref") and data["settlement_wallet_ref"] != owner_principal:
            return Response({"detail": "settlement wallet must belong to fleet owner"}, status=403)
        application = create_application(
            application_type=data["application_type"],
            applicant_principal=owner,
            client_reference=data["client_reference"],
            region=data["region"],
            district=data["district"],
            actor=_actor(request),
        )
        if hasattr(application, "fleet"):
            return Response(ApplicationSerializer(application).data)
        encrypted_values = {}
        for field, context in (
            ("brela_number", "brela"),
            ("tin", "tin"),
            ("bank_details", "bank"),
        ):
            if data.get(field):
                encrypted_values[field] = encrypt_text(
                    data[field],
                    context=f"registry-fleet-{context}:{application.id}",
                )
        try:
            FleetRegistration.objects.create(
                application=application,
                pii_key_version=active_key_version(),
                fleet_type=data["fleet_type"],
                business_name=data["business_name"],
                brela_number_hash=blind_index(data["brela_number"]) if data.get("brela_number") else "",
                brela_number_ciphertext=encrypted_values.get("brela_number").ciphertext if encrypted_values.get("brela_number") else None,
                brela_number_nonce=encrypted_values.get("brela_number").nonce if encrypted_values.get("brela_number") else None,
                tin_hash=blind_index(data["tin"]) if data.get("tin") else "",
                tin_ciphertext=encrypted_values.get("tin").ciphertext if encrypted_values.get("tin") else None,
                tin_nonce=encrypted_values.get("tin").nonce if encrypted_values.get("tin") else None,
                business_license_number=data.get("business_license_number", ""),
                address=data["address"],
                owner_principal=owner_principal,
                declared_fleet_size=data["declared_fleet_size"],
                bank_details_ciphertext=encrypted_values.get("bank_details").ciphertext if encrypted_values.get("bank_details") else None,
                bank_details_nonce=encrypted_values.get("bank_details").nonce if encrypted_values.get("bank_details") else None,
                settlement_wallet_ref=owner_principal,
            )
        except IntegrityError:
            return Response({"detail": "business identifiers are already registered"}, status=409)
        return Response(ApplicationSerializer(application).data, status=201)


@extend_schema(
    tags=["mobility-registry-documents"],
    request=DocumentUploadSerializer,
    responses={201: DocumentSerializer},
)
class DocumentUploadView(APIView):
    permission_classes = [IsDevice]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request, application_id):
        _accessible_application(request, application_id)
        serializer = DocumentUploadSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        uploaded = data["document"]
        try:
            document = upload_document(
                application_id=application_id,
                actor=_actor(request),
                kind=data["kind"],
                original_name=uploaded.name,
                content_type=uploaded.content_type or "application/octet-stream",
                payload=uploaded.read(),
                document_number=data.get("document_number", ""),
                issue_date=data.get("issue_date"),
                expiry_date=data.get("expiry_date"),
            )
        except RegistryError as exc:
            return Response({"detail": str(exc)}, status=409)
        return Response(DocumentSerializer(document).data, status=201)


@extend_schema(tags=["mobility-registry-documents"], responses=DocumentSerializer(many=True))
class DocumentListView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, application_id):
        application = _accessible_application(request, application_id)
        return Response(
            DocumentSerializer(
                application.documents.filter(current=True).order_by("kind"),
                many=True,
            ).data
        )


class DocumentDownloadView(APIView):
    permission_classes = [IsDevice]

    @extend_schema(tags=["mobility-registry-documents"], responses=bytes)
    def get(self, request, document_id):
        document = get_object_or_404(
            RegistryDocument.objects.select_related("application"),
            pk=document_id,
        )
        is_owner = document.application.applicant_principal == request_owner(request)
        if not is_owner:
            _require(request, "mobility_registry.document.read")
            if not may_access_region(request, document.application.region):
                raise PermissionDenied("document region access denied")
        try:
            payload = decrypt_document(document, actor=_actor(request))
        except RegistryError as exc:
            return Response({"detail": str(exc)}, status=409)
        response = HttpResponse(payload, content_type=document.content_type)
        response["Content-Disposition"] = f'attachment; filename="{document.original_name}"'
        response["X-Content-Type-Options"] = "nosniff"
        response["Cache-Control"] = "no-store"
        return response


@extend_schema(tags=["mobility-registry"], request=None, responses=ApplicationSerializer)
class SubmitApplicationView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, application_id):
        try:
            application = submit_application(application_id, actor=_actor(request))
        except RegistryError as exc:
            return Response({"detail": str(exc)}, status=409)
        return Response(ApplicationSerializer(application).data)


@extend_schema(
    tags=["mobility-registry-verification"],
    request=DocumentDecisionSerializer,
    responses=DocumentSerializer,
)
class DocumentReviewView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, document_id):
        _require(request, "mobility_registry.document.review")
        serializer = DocumentDecisionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            document = review_document(
                document_id,
                actor=_actor(request),
                decision=serializer.validated_data["decision"],
                reason=serializer.validated_data.get("reason", ""),
            )
        except RegistryError as exc:
            return Response({"detail": str(exc)}, status=409)
        return Response(DocumentSerializer(document).data)


@extend_schema(
    tags=["mobility-registry-verification"],
    request=WorkflowActionSerializer,
    responses=ApplicationSerializer,
)
class WorkflowActionView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, application_id, action):
        permission = {
            "advance": "mobility_registry.application.review",
            "approve": "mobility_registry.application.approve",
            "reject": "mobility_registry.application.reject",
            "suspend": "mobility_registry.application.suspend",
        }.get(action)
        if not permission:
            return Response({"detail": "unknown workflow action"}, status=404)
        _require(request, permission)
        application = _accessible_application(request, application_id)
        if not may_access_region(request, application.region):
            raise PermissionDenied("application region access denied")
        serializer = WorkflowActionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        try:
            if action == "advance":
                application = advance_stage(
                    application_id,
                    actor=_actor(request),
                    comments=data.get("comments", ""),
                )
            elif action == "approve":
                application = approve_application(
                    application_id,
                    actor=_actor(request),
                    comments=data.get("comments", ""),
                )
            elif action == "reject":
                application = reject_application(
                    application_id,
                    actor=_actor(request),
                    reason=data.get("reason", ""),
                    comments=data.get("comments", ""),
                )
            else:
                application = suspend_application(
                    application_id,
                    actor=_actor(request),
                    reason=data.get("reason", ""),
                )
        except RegistryError as exc:
            return Response({"detail": str(exc)}, status=409)
        return Response(ApplicationSerializer(application).data)


@extend_schema(
    tags=["mobility-registry-verification"],
    request=ExternalVerificationSerializer,
    responses=ApplicationSerializer,
)
class ExternalVerificationView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, application_id):
        _require(request, "mobility_registry.external.verify")
        application = _accessible_application(request, application_id)
        serializer = ExternalVerificationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            result = request_external_verification(
                application.id,
                actor=_actor(request),
                **serializer.validated_data,
            )
        except RegistryError as exc:
            return Response({"detail": str(exc)}, status=409)
        return Response(
            {
                "id": str(result.id),
                "provider": result.provider,
                "check_type": result.check_type,
                "status": result.status,
                "completed_at": result.completed_at,
            }
        )


@extend_schema(
    tags=["mobility-registry-verification"],
    responses=VerificationQueueSerializer,
)
class VerificationDashboardView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        _require(request, "mobility_registry.application.review")
        queryset = RegistryApplication.objects.all()
        expired_documents = RegistryDocument.objects.filter(
            current=True,
            expiry_date__lt=timezone.localdate(),
        )
        payload = {
            "new_applications": queryset.filter(status=ApplicationStatus.SUBMITTED).count(),
            "pending_verification": queryset.filter(status=ApplicationStatus.PENDING_REVIEW).count(),
            "rejected_applications": queryset.filter(status=ApplicationStatus.REJECTED).count(),
            "expired_documents": expired_documents.count(),
            "suspended_drivers": queryset.filter(
                application_type=ApplicationType.DRIVER,
                status=ApplicationStatus.SUSPENDED,
            ).count(),
            "suspended_vehicles": queryset.filter(
                application_type=ApplicationType.VEHICLE,
                status=ApplicationStatus.SUSPENDED,
            ).count(),
            "pending_stations": queryset.filter(
                application_type=ApplicationType.STATION,
                status__in=[ApplicationStatus.SUBMITTED, ApplicationStatus.PENDING_REVIEW],
            ).count(),
            "pending_fleets": queryset.filter(
                application_type__in=[ApplicationType.FLEET, ApplicationType.TRANSPORT_COMPANY],
                status__in=[ApplicationStatus.SUBMITTED, ApplicationStatus.PENDING_REVIEW],
            ).count(),
        }
        return Response(VerificationQueueSerializer(payload).data)


@extend_schema(
    tags=["mobility-registry-compliance"],
    responses=ComplianceDashboardSerializer,
)
class ComplianceDashboardView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        _require(request, "mobility_registry.compliance.read")
        today = timezone.localdate()
        finding_counts = {
            row["severity"]: row["count"]
            for row in ComplianceFinding.objects.filter(status="open")
            .values("severity")
            .annotate(count=Count("id"))
        }
        expiring = {}
        for days in (1, 7, 14, 30):
            expiring[str(days)] = RegistryDocument.objects.filter(
                current=True,
                expiry_date__gte=today,
                expiry_date__lte=today + timezone.timedelta(days=days),
            ).count()
        payload = {
            "open_findings": finding_counts,
            "documents_expiring": expiring,
            "expired_documents": RegistryDocument.objects.filter(
                current=True,
                expiry_date__lt=today,
            ).count(),
            "suspended_applications": RegistryApplication.objects.filter(
                status=ApplicationStatus.SUSPENDED
            ).count(),
            "blocked_applications": RegistryApplication.objects.filter(
                status=ApplicationStatus.BLOCKED
            ).count(),
            "notification_backlog": RegistryNotification.objects.filter(
                status="pending"
            ).count(),
        }
        return Response(ComplianceDashboardSerializer(payload).data)


@extend_schema(
    tags=["mobility-registry-compliance"],
    request=BlacklistCreateSerializer,
    responses={201: BlacklistSerializer},
)
class BlacklistCreateView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        _require(request, "mobility_registry.application.suspend")
        serializer = BlacklistCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            entry = add_blacklist_entry(
                actor=_actor(request),
                **serializer.validated_data,
            )
        except RegistryError as exc:
            return Response({"detail": str(exc)}, status=409)
        return Response(BlacklistSerializer(entry).data, status=201)


@extend_schema(
    tags=["mobility-registry-verification"],
    parameters=[
        OpenApiParameter("status", str, required=False),
        OpenApiParameter("type", str, required=False),
        OpenApiParameter("region", str, required=False),
    ],
    responses=ApplicationSerializer(many=True),
)
class VerificationQueueView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        _require(request, "mobility_registry.application.review")
        queryset = RegistryApplication.objects.all().order_by("created_at")
        principal_region = request.query_params.get("region")
        if principal_region:
            if not may_access_region(request, principal_region):
                raise PermissionDenied("region access denied")
            queryset = queryset.filter(region=principal_region)
        if request.query_params.get("status"):
            queryset = queryset.filter(status=request.query_params["status"])
        if request.query_params.get("type"):
            queryset = queryset.filter(application_type=request.query_params["type"])
        return _paginate(request, queryset, ApplicationSerializer)


@extend_schema(
    tags=["mobility-registry-search"],
    parameters=[
        OpenApiParameter("q", str, required=True),
        OpenApiParameter(
            "field",
            str,
            required=False,
            enum=["name", "phone", "national_id", "vehicle", "engine", "chassis", "fleet", "station"],
        ),
    ],
    responses=RegistrySearchResultSerializer(many=True),
)
class RegistrySearchView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        _require(request, "mobility_registry.search")
        query = request.query_params.get("q", "").strip()
        field = request.query_params.get("field", "name")
        if len(query) < 2:
            return Response({"detail": "search query is too short"}, status=400)
        applications = RegistryApplication.objects.none()
        if field == "name":
            driver_ids = DriverRegistration.objects.filter(
                full_name__icontains=query
            ).values_list("application_id", flat=True)
            fleet_ids = FleetRegistration.objects.filter(
                business_name__icontains=query
            ).values_list("application_id", flat=True)
            station_ids = StationRegistration.objects.filter(
                name__icontains=query
            ).values_list("application_id", flat=True)
            applications = RegistryApplication.objects.filter(
                id__in=[*driver_ids, *fleet_ids, *station_ids]
            )
        elif field in {"phone", "national_id", "engine", "chassis"}:
            digest = blind_index(query)
            mapping = {
                "phone": Q(driver__phone_hash=digest) | Q(station__phone_hash=digest),
                "national_id": Q(driver__national_id_hash=digest),
                "engine": Q(vehicle__engine_number_hash=digest),
                "chassis": Q(vehicle__chassis_number_hash=digest),
            }
            applications = RegistryApplication.objects.filter(mapping[field])
        elif field == "vehicle":
            normalized = query.upper().replace(" ", "")
            applications = RegistryApplication.objects.filter(
                vehicle__registration_number__icontains=normalized
            )
        elif field == "fleet":
            applications = RegistryApplication.objects.filter(
                fleet__business_name__icontains=query
            )
        elif field == "station":
            applications = RegistryApplication.objects.filter(
                Q(station__name__icontains=query) | Q(station__code__icontains=query)
            )
        applications = applications.distinct()[:100]
        results = []
        for application in applications:
            if not may_access_region(request, application.region):
                continue
            display_name = application.application_number
            phone_masked = registration_number = ""
            if application.application_type == ApplicationType.DRIVER:
                display_name, phone_masked = application.driver.full_name, application.driver.phone_masked
            elif application.application_type == ApplicationType.VEHICLE:
                display_name = application.vehicle.registration_number
                registration_number = application.vehicle.registration_number
            elif application.application_type == ApplicationType.STATION:
                display_name, phone_masked = application.station.name, application.station.phone_masked
            else:
                display_name = application.fleet.business_name
            results.append(
                {
                    "application": application,
                    "display_name": display_name,
                    "phone_masked": phone_masked,
                    "registration_number": registration_number,
                }
            )
        return Response(RegistrySearchResultSerializer(results, many=True).data)


@extend_schema(tags=["mobility-registry"], responses=WorkflowTransitionSerializer(many=True))
class ApplicationAuditView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, application_id):
        application = _accessible_application(request, application_id)
        return Response(WorkflowTransitionSerializer(application.transitions.all(), many=True).data)
