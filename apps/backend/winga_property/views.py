"""Winga Property REST API."""
from __future__ import annotations

from django.db import models
from django.shortcuts import get_object_or_404
from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from payments.auth import IsDevice

from .permissions import IsPropertyOpsReader, IsPropertyOpsWriter

from . import services
from .models import (
    PropertyCategory,
    PropertyFavorite,
    PropertyListing,
    PropertyLiveMessage,
    PropertyLiveSession,
    PropertyMedia,
    PropertyOwner,
    PropertyType,
    PropertyVerificationEvent,
    PropertyViewingPass,
    PropertyViewingPassStatus,
    PropertyViewEvent,
    PropertyWingaAssignment,
    PropertyApplication,
    PropertyLease,
    PropertyLeasePayment,
    PropertyMoveWorkflow,
    PropertyModerationReport,
    PropertyDispute,
    SavedSearch,
)
from .serializers import (
    PropertyCategorySerializer,
    PropertyFavoriteSerializer,
    PropertyListingCreateSerializer,
    PropertyListingPatchSerializer,
    PropertyListingSerializer,
    PropertyLiveMessageSerializer,
    PropertyLiveSessionSerializer,
    PropertyMediaCreateSerializer,
    PropertyMediaSerializer,
    PropertyOwnerSerializer,
    PropertySharedDocumentSerializer,
    PropertyTypeSerializer,
    PropertyVerificationEventSerializer,
    PropertyViewingAppointmentSerializer,
    PropertyViewingPassSerializer,
    PropertyWingaAssignmentDetailSerializer,
    PropertyWingaAssignmentSerializer,
    PropertyWingaProfileSerializer,
    RelocationAssistSerializer,
    SavedSearchSerializer,
    ScheduleAppointmentSerializer,
    ShareDocumentSerializer,
    ViewingPassPlanSerializer,
    CopilotChatSerializer,
    NegotiationAssistSerializer,
    ChatMessagePostSerializer,
    PropertyApplicationCreateSerializer,
    PropertyApplicationDocumentSerializer,
    PropertyLeaseSerializer,
    ScheduleMoveSerializer,
    ReportListingSerializer,
    ResolveModerationSerializer,
    OpenDisputeSerializer,
    ResolveDisputeSerializer,
    AssignDisputeSerializer,
)
from .services import PropertyError
from . import intelligence
from . import experience as experience_svc
from . import copilot as copilot_svc
from . import human_winga as human_winga_svc
from . import transactions as transactions_svc
from . import operations as operations_svc


def _principal(request) -> str:
    auth = getattr(request, "auth", None)
    if auth is not None and getattr(auth, "owner", None):
        return auth.owner
    return "anonymous"


class CategoryListView(APIView):
    permission_classes = [IsDevice]

    @extend_schema(responses=PropertyCategorySerializer(many=True))
    def get(self, request):
        qs = PropertyCategory.objects.filter(active=True)
        return Response(PropertyCategorySerializer(qs, many=True).data)


class TypeListView(APIView):
    permission_classes = [IsDevice]

    @extend_schema(responses=PropertyTypeSerializer(many=True))
    def get(self, request):
        qs = PropertyType.objects.filter(active=True).select_related("category")
        category = request.query_params.get("category")
        if category:
            qs = qs.filter(category__code=category)
        return Response(PropertyTypeSerializer(qs, many=True).data)


class OwnerProfileView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        owner = PropertyOwner.objects.filter(principal=_principal(request)).first()
        if owner is None:
            return Response({"detail": "owner profile not found"}, status=404)
        return Response(PropertyOwnerSerializer(owner).data)

    def post(self, request):
        ser = PropertyOwnerSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        owner = services.get_or_create_owner(
            principal=_principal(request),
            display_name=ser.validated_data.get("display_name", ""),
            phone=ser.validated_data.get("phone", ""),
            email=ser.validated_data.get("email", ""),
            role=ser.validated_data.get("role", "owner"),
            bio=ser.validated_data.get("bio", ""),
        )
        return Response(PropertyOwnerSerializer(owner).data, status=201)


class ListingListCreateView(APIView):
    permission_classes = [IsDevice]

    @extend_schema(operation_id="winga_property_listings_list")
    def get(self, request):
        mine = request.query_params.get("mine") in {"1", "true", "yes"}
        verified_only = request.query_params.get("verified") in {"1", "true", "yes"}
        qs = services.search_listings(
            q=request.query_params.get("q", ""),
            category=request.query_params.get("category", ""),
            property_type=request.query_params.get("type", ""),
            transaction_type=request.query_params.get("transaction", ""),
            region=request.query_params.get("region", ""),
            district=request.query_params.get("district", ""),
            min_price=_int_or_none(request.query_params.get("min_price")),
            max_price=_int_or_none(request.query_params.get("max_price")),
            beds=_int_or_none(request.query_params.get("beds")),
            baths=_int_or_none(request.query_params.get("baths")),
            verified_only=verified_only and not mine,
            owner_principal=_principal(request) if mine else "",
        )
        return Response(PropertyListingSerializer(qs, many=True).data)

    def post(self, request):
        ser = PropertyListingCreateSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        d = ser.validated_data
        owner = services.get_or_create_owner(
            principal=_principal(request),
            display_name=request.data.get("owner_name", _principal(request)),
        )
        category = get_object_or_404(PropertyCategory, code=d["category_code"], active=True)
        prop_type = get_object_or_404(
            PropertyType,
            code=d["property_type_code"],
            category=category,
            active=True,
        )
        listing = services.create_listing(
            owner=owner,
            category=category,
            property_type=prop_type,
            transaction_type=d["transaction_type"],
            title=d["title"],
            description=d.get("description", ""),
            currency=d.get("currency", "TZS"),
            price_minor=d["price_minor"],
            deposit_minor=d.get("deposit_minor", 0),
            beds=d.get("beds", 0),
            baths=d.get("baths", 0),
            area_sqm=d.get("area_sqm", 0),
            address_line=d.get("address_line", ""),
            ward=d.get("ward", ""),
            district=d.get("district", ""),
            region=d.get("region", ""),
            latitude=d.get("latitude", 0),
            longitude=d.get("longitude", 0),
            attributes=d.get("attributes", {}),
        )
        return Response(PropertyListingSerializer(listing).data, status=201)


class ListingDetailView(APIView):
    permission_classes = [IsDevice]

    @extend_schema(operation_id="winga_property_listings_retrieve")
    def get(self, request, listing_id):
        listing = get_object_or_404(
            PropertyListing.objects.select_related("category", "property_type", "owner").prefetch_related(
                "media"
            ),
            pk=listing_id,
        )
        intelligence.record_view(principal=_principal(request), listing=listing)
        unlocked = experience_svc.has_listing_unlock(
            principal=_principal(request), listing_id=listing.id
        )
        return Response(
            PropertyListingSerializer(listing, context={"unlocked": unlocked}).data
        )

    def patch(self, request, listing_id):
        listing = get_object_or_404(PropertyListing, pk=listing_id, owner__principal=_principal(request))
        ser = PropertyListingPatchSerializer(data=request.data, partial=True)
        ser.is_valid(raise_exception=True)
        listing = services.update_listing(listing=listing, **ser.validated_data)
        return Response(PropertyListingSerializer(listing).data)

    def delete(self, request, listing_id):
        listing = get_object_or_404(PropertyListing, pk=listing_id, owner__principal=_principal(request))
        listing.active = False
        listing.save(update_fields=["active", "updated_at"])
        return Response(status=204)


class ListingMediaView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, listing_id):
        listing = get_object_or_404(PropertyListing, pk=listing_id, owner__principal=_principal(request))
        ser = PropertyMediaCreateSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        media = services.add_media(listing=listing, **ser.validated_data)
        return Response(PropertyMediaSerializer(media).data, status=201)


class ListingSubmitVerificationView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, listing_id):
        listing = get_object_or_404(PropertyListing, pk=listing_id, owner__principal=_principal(request))
        try:
            listing = services.submit_for_verification(listing=listing, actor=_principal(request))
        except PropertyError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(PropertyListingSerializer(listing).data)


class ListingVerifyView(APIView):
    """Admin/ops verification — foundation hook."""

    permission_classes = [IsDevice]

    def post(self, request, listing_id):
        listing = get_object_or_404(PropertyListing, pk=listing_id)
        approve = request.data.get("approve", True) not in {False, "false", "0"}
        notes = str(request.data.get("notes", ""))
        listing = services.verify_listing(
            listing=listing,
            actor=_principal(request),
            approve=approve,
            notes=notes,
        )
        return Response(PropertyListingSerializer(listing).data)


class ListingVerificationHistoryView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, listing_id):
        listing = get_object_or_404(PropertyListing, pk=listing_id)
        events = PropertyVerificationEvent.objects.filter(listing=listing)[:50]
        return Response(PropertyVerificationEventSerializer(events, many=True).data)


class MapPinsView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        pins = services.map_pins(
            region=request.query_params.get("region", ""),
            limit=int(request.query_params.get("limit", 200)),
        )
        return Response({"pins": pins})


class FavoriteListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        favs = PropertyFavorite.objects.filter(principal=_principal(request)).select_related(
            "listing__category", "listing__property_type", "listing__owner"
        ).prefetch_related("listing__media")[:100]
        return Response(PropertyFavoriteSerializer(favs, many=True).data)

    def post(self, request):
        listing_id = request.data.get("listing_id")
        if not listing_id:
            return Response({"detail": "listing_id required"}, status=400)
        listing = get_object_or_404(PropertyListing, pk=listing_id, active=True)
        added = services.toggle_favorite(principal=_principal(request), listing=listing)
        return Response({"favorited": added})


class SavedSearchListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        rows = SavedSearch.objects.filter(principal=_principal(request), active=True)[:50]
        return Response(SavedSearchSerializer(rows, many=True).data)

    def post(self, request):
        name = request.data.get("name", "My search")
        filters = request.data.get("filters", {})
        row = services.create_saved_search(
            principal=_principal(request),
            name=name,
            filters=filters if isinstance(filters, dict) else {},
        )
        return Response(SavedSearchSerializer(row).data, status=201)


def _int_or_none(raw: str | None) -> int | None:
    if raw in (None, ""):
        return None
    try:
        return int(raw)
    except (TypeError, ValueError):
        return None


def _float_or_none(raw: str | None) -> float | None:
    if raw in (None, ""):
        return None
    try:
        return float(raw)
    except (TypeError, ValueError):
        return None


class DiscoveryAdvancedSearchView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        listings = intelligence.advanced_search(
            q=request.query_params.get("q", ""),
            lifestyle=request.query_params.get("lifestyle", ""),
            category=request.query_params.get("category", ""),
            property_type=request.query_params.get("type", ""),
            transaction_type=request.query_params.get("transaction", ""),
            region=request.query_params.get("region", ""),
            district=request.query_params.get("district", ""),
            min_price=_int_or_none(request.query_params.get("min_price")),
            max_price=_int_or_none(request.query_params.get("max_price")),
            beds=_int_or_none(request.query_params.get("beds")),
            baths=_int_or_none(request.query_params.get("baths")),
            verified_only=request.query_params.get("verified", "1") in {"1", "true", "yes"},
            min_walkability_e4=_int_or_none(request.query_params.get("min_walkability_e4")),
            min_safety_e4=_int_or_none(request.query_params.get("min_safety_e4")),
            limit=int(request.query_params.get("limit", 50)),
        )
        return Response(PropertyListingSerializer(listings, many=True).data)


class DiscoveryAiSearchView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        result = intelligence.ai_property_search(
            query=str(request.data.get("query", "")),
            principal=_principal(request),
            lifestyle=str(request.data.get("lifestyle", "")),
            neighborhood=str(request.data.get("neighborhood", "")),
            limit=int(request.data.get("limit", 20)),
        )
        listings = PropertyListing.objects.filter(id__in=result["listing_ids"]).select_related(
            "category", "property_type", "owner"
        ).prefetch_related("media")
        return Response(
            {
                **result,
                "listings": PropertyListingSerializer(listings, many=True).data,
            }
        )


class DiscoveryRecommendationsView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        limit = int(request.query_params.get("limit", 6))
        listings = intelligence.recommend_listings(
            principal=_principal(request), limit=limit
        )
        return Response(PropertyListingSerializer(listings, many=True).data)


class DiscoveryRecentlyViewedView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        limit = int(request.query_params.get("limit", 8))
        listings = intelligence.recently_viewed(
            principal=_principal(request), limit=limit
        )
        return Response(PropertyListingSerializer(listings, many=True).data)


class DiscoveryCompareView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        ids = request.data.get("listing_ids") or []
        if not isinstance(ids, list) or not ids:
            return Response({"detail": "listing_ids required"}, status=400)
        return Response(intelligence.compare_listings(listing_ids=[str(i) for i in ids]))


class ListingIntelligenceView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, listing_id):
        listing = get_object_or_404(PropertyListing, pk=listing_id, active=True)
        return Response(intelligence.neighborhood_intelligence(listing=listing))


class ListingCommuteView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, listing_id):
        listing = get_object_or_404(PropertyListing, pk=listing_id, active=True)
        dest_lat = _float_or_none(request.query_params.get("dest_lat"))
        dest_lng = _float_or_none(request.query_params.get("dest_lng"))
        if dest_lat is None or dest_lng is None:
            return Response({"detail": "dest_lat and dest_lng required"}, status=400)
        mode = request.query_params.get("mode", "driving")
        return Response(
            intelligence.commute_estimate(
                listing=listing, dest_lat=dest_lat, dest_lng=dest_lng, mode=mode
            )
        )


class ListingVisitScoreView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, listing_id):
        listing = get_object_or_404(PropertyListing, pk=listing_id, active=True)
        dest_lat = _float_or_none(request.query_params.get("dest_lat"))
        dest_lng = _float_or_none(request.query_params.get("dest_lng"))
        return Response(
            intelligence.visit_decision_score(
                listing=listing, dest_lat=dest_lat, dest_lng=dest_lng
            )
        )


class MapClustersView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        clusters = intelligence.map_clusters(
            region=request.query_params.get("region", ""),
            grid_size=float(request.query_params.get("grid_size", 0.02)),
        )
        return Response({"clusters": clusters})


class ListingExperienceView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, listing_id):
        listing = get_object_or_404(
            PropertyListing.objects.prefetch_related("media"),
            pk=listing_id,
            active=True,
        )
        return Response(experience_svc.listing_experience(listing=listing))


class ViewingPassPlansView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        return Response({"plans": ViewingPassPlanSerializer(experience_svc.viewing_pass_plans(), many=True).data})


class ViewingPassListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        rows = PropertyViewingPass.objects.filter(principal=_principal(request))[:20]
        return Response(PropertyViewingPassSerializer(rows, many=True).data)

    def post(self, request):
        plan_code = str(request.data.get("plan_code", ""))
        listing_id = request.data.get("listing_id")
        try:
            row = experience_svc.create_viewing_pass(
                principal=_principal(request),
                plan_code=plan_code,
                listing_id=listing_id,
            )
        except experience_svc.ExperienceError as exc:
            return Response({"detail": str(exc)}, status=400)
        except PropertyListing.DoesNotExist:
            return Response({"detail": "listing not found"}, status=404)
        return Response(PropertyViewingPassSerializer(row).data, status=201)


class ViewingPassPayView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, pass_id):
        from commerce.services import CommerceError

        key = request.headers.get("Idempotency-Key", "").strip()
        if not key:
            return Response({"detail": "Idempotency-Key required"}, status=400)
        try:
            row = experience_svc.collect_viewing_pass_payment(
                pass_id=pass_id,
                principal=_principal(request),
                actor=_principal(request),
                idempotency_key=key,
            )
        except CommerceError as exc:
            return Response({"detail": str(exc)}, status=409)
        except experience_svc.ExperienceError as exc:
            return Response({"detail": str(exc)}, status=400)
        except PropertyViewingPass.DoesNotExist:
            return Response({"detail": "not found"}, status=404)
        return Response(PropertyViewingPassSerializer(row).data)


class ViewingPassVerifyView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        token = str(request.data.get("qr_token", ""))
        try:
            result = experience_svc.verify_viewing_pass_qr(qr_token=token)
        except experience_svc.ExperienceError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(result)


class ViewingPassUnlockListingView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, listing_id):
        listing = get_object_or_404(PropertyListing, pk=listing_id, active=True)
        pass_id = request.data.get("pass_id")
        if not pass_id:
            return Response({"detail": "pass_id required"}, status=400)
        try:
            row = PropertyViewingPass.objects.get(
                pk=pass_id,
                principal=_principal(request),
                status=PropertyViewingPassStatus.ACTIVE,
            )
            row = experience_svc.activate_listing_on_pass(pass_row=row, listing_id=listing.id)
        except PropertyViewingPass.DoesNotExist:
            return Response({"detail": "pass not found"}, status=404)
        except experience_svc.ExperienceError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(
            {
                "pass": PropertyViewingPassSerializer(row).data,
                "listing": PropertyListingSerializer(
                    listing, context={"unlocked": True}
                ).data,
            }
        )


class ListingLiveSessionListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, listing_id):
        listing = get_object_or_404(PropertyListing, pk=listing_id, active=True)
        principal = _principal(request)
        sessions = PropertyLiveSession.objects.filter(listing=listing).filter(
            models.Q(customer_principal=principal) | models.Q(owner_principal=principal)
        )[:20]
        return Response(PropertyLiveSessionSerializer(sessions, many=True).data)

    def post(self, request, listing_id):
        listing = get_object_or_404(
            PropertyListing.objects.select_related("owner"),
            pk=listing_id,
            active=True,
        )
        scheduled_at = request.data.get("scheduled_at")
        notes = str(request.data.get("notes", ""))
        session = experience_svc.request_live_session(
            listing=listing,
            customer_principal=_principal(request),
            scheduled_at=scheduled_at,
            notes=notes,
        )
        return Response(PropertyLiveSessionSerializer(session).data, status=201)


class LiveSessionDetailView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, session_id):
        session = get_object_or_404(PropertyLiveSession, pk=session_id)
        principal = _principal(request)
        if principal not in {session.customer_principal, session.owner_principal}:
            return Response({"detail": "forbidden"}, status=403)
        return Response(PropertyLiveSessionSerializer(session).data)


class LiveSessionStartView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, session_id):
        session = get_object_or_404(PropertyLiveSession, pk=session_id)
        try:
            session = experience_svc.start_live_session(
                session=session, actor=_principal(request)
            )
        except experience_svc.ExperienceError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(PropertyLiveSessionSerializer(session).data)


class LiveSessionJoinView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, session_id):
        session = get_object_or_404(PropertyLiveSession, pk=session_id)
        try:
            session = experience_svc.join_live_session(
                session=session, actor=_principal(request)
            )
        except experience_svc.ExperienceError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(PropertyLiveSessionSerializer(session).data)


class LiveSessionEndView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, session_id):
        session = get_object_or_404(PropertyLiveSession, pk=session_id)
        try:
            session = experience_svc.end_live_session(
                session=session, actor=_principal(request)
            )
        except experience_svc.ExperienceError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(PropertyLiveSessionSerializer(session).data)


class LiveSessionMessagesView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, session_id):
        session = get_object_or_404(PropertyLiveSession, pk=session_id)
        principal = _principal(request)
        if principal not in {session.customer_principal, session.owner_principal}:
            return Response({"detail": "forbidden"}, status=403)
        messages = PropertyLiveMessage.objects.filter(session=session)[:100]
        return Response(PropertyLiveMessageSerializer(messages, many=True).data)

    def post(self, request, session_id):
        session = get_object_or_404(PropertyLiveSession, pk=session_id)
        body = str(request.data.get("body", "")).strip()
        if not body:
            return Response({"detail": "body required"}, status=400)
        try:
            msg = experience_svc.post_live_message(
                session=session,
                sender=_principal(request),
                body=body,
            )
        except experience_svc.ExperienceError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(PropertyLiveMessageSerializer(msg).data, status=201)


class CopilotChatView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        ser = CopilotChatSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        result = copilot_svc.property_copilot(
            query=ser.validated_data["query"],
            principal=_principal(request),
            listing_id=str(ser.validated_data["listing_id"])
            if ser.validated_data.get("listing_id")
            else None,
        )
        return Response(result)


class CopilotRankingsView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        raw = request.query_params.get("listing_ids", "")
        ids = [s.strip() for s in raw.split(",") if s.strip()]
        ranked = copilot_svc.rank_listings(listing_ids=ids, principal=_principal(request))
        return Response({"rankings": ranked})


class ListingNegotiationAssistView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, listing_id):
        listing = get_object_or_404(PropertyListing, pk=listing_id, active=True)
        ser = NegotiationAssistSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        return Response(
            copilot_svc.negotiation_assist(
                listing=listing,
                offer_minor=ser.validated_data["offer_minor"],
                principal=_principal(request),
            )
        )


class ListingRelocationAssistView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, listing_id):
        listing = get_object_or_404(PropertyListing, pk=listing_id, active=True)
        ser = RelocationAssistSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        return Response(
            copilot_svc.relocation_assist(
                listing=listing,
                destination=ser.validated_data["destination"],
                principal=_principal(request),
            )
        )


class PropertyWingaListView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        wingas = human_winga_svc.list_property_wingas()
        data = [
            {
                **human_winga_svc.winga_profile_payload(w.id),
                "principal": w.principal,
            }
            for w in wingas
        ]
        return Response({"wingas": data})


class PropertyWingaLeaderboardView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        return Response({"leaderboard": human_winga_svc.winga_leaderboard()})


class ListingAssignWingaView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, listing_id):
        listing = get_object_or_404(PropertyListing, pk=listing_id, active=True)
        try:
            assignment = human_winga_svc.assign_winga(
                listing=listing,
                customer_principal=_principal(request),
                notes=str(request.data.get("notes", "")),
            )
        except human_winga_svc.HumanWingaError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(
            PropertyWingaAssignmentDetailSerializer(assignment).data,
            status=201,
        )


class AssignmentListView(APIView):
    permission_classes = [IsDevice]

    @extend_schema(operation_id="winga_property_assignments_list")
    def get(self, request):
        rows = human_winga_svc.get_customer_assignments(principal=_principal(request))
        return Response(PropertyWingaAssignmentSerializer(rows, many=True).data)


class AssignmentDetailView(APIView):
    permission_classes = [IsDevice]

    @extend_schema(operation_id="winga_property_assignments_retrieve")
    def get(self, request, assignment_id):
        assignment = get_object_or_404(
            PropertyWingaAssignment.objects.select_related("listing").prefetch_related(
                "timeline", "documents", "appointments"
            ),
            pk=assignment_id,
            customer_principal=_principal(request),
        )
        return Response(PropertyWingaAssignmentDetailSerializer(assignment).data)


class AssignmentDocumentsView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, assignment_id):
        assignment = get_object_or_404(
            PropertyWingaAssignment, pk=assignment_id, customer_principal=_principal(request)
        )
        return Response(
            PropertySharedDocumentSerializer(assignment.documents.all(), many=True).data
        )

    def post(self, request, assignment_id):
        assignment = get_object_or_404(
            PropertyWingaAssignment, pk=assignment_id, customer_principal=_principal(request)
        )
        ser = ShareDocumentSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        doc = human_winga_svc.share_document(
            assignment=assignment,
            title=ser.validated_data["title"],
            url=ser.validated_data["url"],
            shared_by=_principal(request),
        )
        return Response(PropertySharedDocumentSerializer(doc).data, status=201)


class AssignmentAppointmentsView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, assignment_id):
        assignment = get_object_or_404(
            PropertyWingaAssignment, pk=assignment_id, customer_principal=_principal(request)
        )
        return Response(
            PropertyViewingAppointmentSerializer(assignment.appointments.all(), many=True).data
        )

    def post(self, request, assignment_id):
        assignment = get_object_or_404(
            PropertyWingaAssignment, pk=assignment_id, customer_principal=_principal(request)
        )
        ser = ScheduleAppointmentSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        appt = human_winga_svc.schedule_appointment(
            assignment=assignment,
            scheduled_at=ser.validated_data["scheduled_at"],
            location_notes=ser.validated_data.get("location_notes", ""),
            actor=_principal(request),
        )
        return Response(PropertyViewingAppointmentSerializer(appt).data, status=201)


class AssignmentChatView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, assignment_id):
        assignment = get_object_or_404(PropertyWingaAssignment, pk=assignment_id)
        try:
            messages = human_winga_svc.list_chat_messages(
                assignment=assignment, principal=_principal(request)
            )
        except human_winga_svc.HumanWingaError as exc:
            return Response({"detail": str(exc)}, status=403)
        return Response({"messages": messages})

    def post(self, request, assignment_id):
        assignment = get_object_or_404(PropertyWingaAssignment, pk=assignment_id)
        ser = ChatMessagePostSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        try:
            msg = human_winga_svc.post_chat_message(
                assignment=assignment,
                principal=_principal(request),
                text=ser.validated_data["text"],
            )
        except human_winga_svc.HumanWingaError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(msg, status=201)


class AssignmentCommissionPreviewView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, assignment_id):
        assignment = get_object_or_404(
            PropertyWingaAssignment.objects.select_related("listing"),
            pk=assignment_id,
            customer_principal=_principal(request),
        )
        return Response(human_winga_svc.commission_preview(amount_minor=assignment.listing.price_minor))


class ListingApplicationCreateView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, listing_id):
        listing = get_object_or_404(PropertyListing, pk=listing_id, active=True)
        ser = PropertyApplicationCreateSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        d = ser.validated_data
        try:
            app = transactions_svc.create_application(
                listing=listing,
                applicant_principal=_principal(request),
                employment_status=d.get("employment_status", ""),
                monthly_income_minor=d.get("monthly_income_minor", 0),
                national_id=d.get("national_id", ""),
                move_in_date=d.get("move_in_date"),
                notes=d.get("notes", ""),
            )
        except transactions_svc.TransactionError as exc:
            return Response({"detail": str(exc)}, status=400)
        payload = transactions_svc.application_payload(app)
        return Response(payload, status=201)


class ApplicationListView(APIView):
    permission_classes = [IsDevice]

    @extend_schema(operation_id="winga_property_applications_list")
    def get(self, request):
        rows = transactions_svc.list_applications(principal=_principal(request))
        return Response(
            {"applications": [transactions_svc.application_payload(r) for r in rows]}
        )


class ApplicationDetailView(APIView):
    permission_classes = [IsDevice]

    @extend_schema(operation_id="winga_property_applications_retrieve")
    def get(self, request, application_id):
        app = get_object_or_404(
            PropertyApplication.objects.select_related("listing").prefetch_related(
                "documents", "verifications"
            ),
            pk=application_id,
            applicant_principal=_principal(request),
        )
        payload = transactions_svc.application_payload(app)
        if hasattr(app, "lease"):
            payload["lease"] = transactions_svc.lease_payload(app.lease)
        return Response(payload)


class ApplicationSubmitView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, application_id):
        app = get_object_or_404(
            PropertyApplication, pk=application_id, applicant_principal=_principal(request)
        )
        try:
            app = transactions_svc.submit_application(application=app, actor=_principal(request))
        except transactions_svc.TransactionError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(transactions_svc.application_payload(app))


class ApplicationDocumentsView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, application_id):
        app = get_object_or_404(
            PropertyApplication, pk=application_id, applicant_principal=_principal(request)
        )
        ser = PropertyApplicationDocumentSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        d = ser.validated_data
        try:
            doc = transactions_svc.upload_application_document(
                application=app,
                kind=d.get("kind", "other"),
                title=d["title"],
                url=d["url"],
                uploaded_by=_principal(request),
            )
        except transactions_svc.TransactionError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(
            {
                "id": str(doc.id),
                "kind": doc.kind,
                "title": doc.title,
                "url": doc.url,
            },
            status=201,
        )


class ApplicationVerifyIdentityView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, application_id):
        app = get_object_or_404(
            PropertyApplication, pk=application_id, applicant_principal=_principal(request)
        )
        try:
            check = transactions_svc.verify_identity(application=app, actor=_principal(request))
        except transactions_svc.TransactionError as exc:
            return Response({"detail": str(exc)}, status=400)
        except RuntimeError as exc:
            return Response({"detail": str(exc)}, status=503)
        return Response(
            {
                "check_kind": check.check_kind,
                "status": check.status,
                "provider_ref": check.provider_ref,
                "details": check.details,
            }
        )


class ApplicationVerifyIncomeView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, application_id):
        app = get_object_or_404(
            PropertyApplication, pk=application_id, applicant_principal=_principal(request)
        )
        try:
            check = transactions_svc.verify_income(application=app, actor=_principal(request))
        except transactions_svc.TransactionError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(
            {
                "check_kind": check.check_kind,
                "status": check.status,
                "details": check.details,
            }
        )


class ApplicationApproveView(APIView):
    """Owner/ops approval after verification checks pass."""

    permission_classes = [IsDevice]

    def post(self, request, application_id):
        app = get_object_or_404(
            PropertyApplication.objects.select_related("listing__owner"),
            pk=application_id,
        )
        try:
            app = transactions_svc.approve_application(application=app, actor=_principal(request))
        except transactions_svc.TransactionError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(transactions_svc.application_payload(app))


class ApplicationGenerateLeaseView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, application_id):
        app = get_object_or_404(
            PropertyApplication.objects.select_related("listing"),
            pk=application_id,
            applicant_principal=_principal(request),
        )
        try:
            lease = transactions_svc.generate_lease(application=app, actor=_principal(request))
        except transactions_svc.TransactionError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(transactions_svc.lease_payload(lease), status=201)


class LeaseDetailView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, lease_id):
        lease = get_object_or_404(
            PropertyLease.objects.prefetch_related("payments", "move_workflows"),
            pk=lease_id,
        )
        principal = _principal(request)
        if principal not in {lease.tenant_principal, lease.owner_principal}:
            return Response({"detail": "forbidden"}, status=403)
        return Response(transactions_svc.lease_payload(lease))


class LeaseSignView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, lease_id):
        lease = get_object_or_404(PropertyLease, pk=lease_id)
        try:
            lease = transactions_svc.sign_lease(lease=lease, actor=_principal(request))
        except transactions_svc.TransactionError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(transactions_svc.lease_payload(lease))


class LeasePaymentPayView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, payment_id):
        from commerce.services import CommerceError

        key = request.headers.get("Idempotency-Key", "").strip()
        if not key:
            return Response({"detail": "Idempotency-Key required"}, status=400)
        payment = get_object_or_404(PropertyLeasePayment, pk=payment_id)
        try:
            payment = transactions_svc.collect_lease_payment(
                payment=payment,
                payer_principal=_principal(request),
                actor=_principal(request),
                idempotency_key=key,
            )
        except CommerceError as exc:
            return Response({"detail": str(exc)}, status=409)
        except transactions_svc.TransactionError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(
            {
                "id": str(payment.id),
                "kind": payment.kind,
                "status": payment.status,
                "amount_minor": payment.amount_minor,
                "payment_ref": payment.payment_ref,
                "paid_at": payment.paid_at.isoformat() if payment.paid_at else None,
            }
        )


class LeaseRenewView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, lease_id):
        lease = get_object_or_404(PropertyLease, pk=lease_id)
        months = int(request.data.get("months", 12))
        try:
            lease = transactions_svc.renew_lease(
                lease=lease, actor=_principal(request), months=months
            )
        except transactions_svc.TransactionError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(transactions_svc.lease_payload(lease))


class LeaseMoveWorkflowView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, lease_id):
        lease = get_object_or_404(PropertyLease, pk=lease_id)
        ser = ScheduleMoveSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        d = ser.validated_data
        try:
            workflow = transactions_svc.schedule_move_workflow(
                lease=lease,
                phase=d["phase"],
                scheduled_at=d["scheduled_at"],
                notes=d.get("notes", ""),
                actor=_principal(request),
            )
        except transactions_svc.TransactionError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(
            {
                "id": str(workflow.id),
                "phase": workflow.phase,
                "status": workflow.status,
                "scheduled_at": workflow.scheduled_at.isoformat(),
                "checklist": workflow.checklist,
            },
            status=201,
        )


class MoveWorkflowCompleteView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, workflow_id):
        workflow = get_object_or_404(PropertyMoveWorkflow, pk=workflow_id)
        try:
            workflow = transactions_svc.complete_move_workflow(
                workflow=workflow, actor=_principal(request)
            )
        except transactions_svc.TransactionError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(
            {
                "id": str(workflow.id),
                "phase": workflow.phase,
                "status": workflow.status,
                "checklist": workflow.checklist,
                "completed_at": workflow.completed_at.isoformat()
                if workflow.completed_at
                else None,
            }
        )


class OpsDashboardView(APIView):
    permission_classes = [IsDevice, IsPropertyOpsReader]

    def get(self, request):
        region = request.query_params.get("region", "")
        return Response(operations_svc.executive_dashboard(region=region))


class OpsAnalyticsView(APIView):
    permission_classes = [IsDevice, IsPropertyOpsReader]

    def get(self, request):
        region = request.query_params.get("region", "")
        days = int(request.query_params.get("days", 30))
        return Response(operations_svc.analytics_summary(region=region, days=days))


class OpsModerationQueueView(APIView):
    permission_classes = [IsDevice, IsPropertyOpsReader]

    def get(self, request):
        limit = int(request.query_params.get("limit", 50))
        return Response(operations_svc.moderation_queue(limit=limit))


class ListingReportView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, listing_id):
        listing = get_object_or_404(PropertyListing, pk=listing_id, active=True)
        ser = ReportListingSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        report = operations_svc.report_listing(
            listing=listing,
            reporter_principal=_principal(request),
            reason=ser.validated_data["reason"],
            notes=ser.validated_data.get("notes", ""),
        )
        return Response(operations_svc._report_payload(report), status=201)


class ListingFraudSignalsView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, listing_id):
        listing = get_object_or_404(PropertyListing, pk=listing_id)
        return Response(
            operations_svc.listing_fraud_signals(
                listing=listing, principal=_principal(request)
            )
        )


class ApplicationFraudSignalsView(APIView):
    permission_classes = [IsDevice, IsPropertyOpsReader]

    def get(self, request, application_id):
        app = get_object_or_404(PropertyApplication, pk=application_id)
        return Response(
            operations_svc.application_fraud_signals(
                application=app, principal=_principal(request)
            )
        )


class ModerationResolveView(APIView):
    permission_classes = [IsDevice, IsPropertyOpsWriter]

    def post(self, request, report_id):
        report = get_object_or_404(PropertyModerationReport, pk=report_id)
        ser = ResolveModerationSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        report = operations_svc.resolve_moderation_report(
            report=report,
            actor=_principal(request),
            action=ser.validated_data["action"],
            notes=ser.validated_data.get("notes", ""),
        )
        return Response(operations_svc._report_payload(report))


class OpsListingSuspendView(APIView):
    permission_classes = [IsDevice, IsPropertyOpsWriter]

    def post(self, request, listing_id):
        listing = get_object_or_404(PropertyListing, pk=listing_id)
        reason = str(request.data.get("reason", ""))
        listing = operations_svc.suspend_listing(
            listing=listing, actor=_principal(request), reason=reason
        )
        return Response(PropertyListingSerializer(listing).data)


class DisputeListCreateView(APIView):
    permission_classes = [IsDevice]

    def get_permissions(self):
        if self.request.method == "GET":
            return [IsDevice(), IsPropertyOpsReader()]
        return [IsDevice()]

    def get(self, request):
        status = request.query_params.get("status", "")
        disputes = operations_svc.list_disputes(status=status)
        return Response({"disputes": [operations_svc.dispute_payload(d) for d in disputes]})

    def post(self, request):
        ser = OpenDisputeSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        d = ser.validated_data
        listing = None
        lease = None
        if d["subject_type"] == "listing":
            listing = get_object_or_404(PropertyListing, pk=d["subject_id"])
        elif d["subject_type"] == "lease":
            lease = get_object_or_404(PropertyLease, pk=d["subject_id"])
            listing = lease.listing
        elif d["subject_type"] == "application":
            app = get_object_or_404(PropertyApplication, pk=d["subject_id"])
            listing = app.listing
        dispute = operations_svc.open_dispute(
            subject_type=d["subject_type"],
            subject_id=d["subject_id"],
            opened_by=_principal(request),
            reason=d["reason"],
            listing=listing,
            lease=lease,
        )
        return Response(operations_svc.dispute_payload(dispute), status=201)


class DisputeAssignView(APIView):
    permission_classes = [IsDevice, IsPropertyOpsWriter]

    def post(self, request, dispute_id):
        dispute = get_object_or_404(PropertyDispute, pk=dispute_id)
        ser = AssignDisputeSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        dispute = operations_svc.assign_dispute(
            dispute=dispute,
            ops_principal=ser.validated_data["ops_principal"],
            actor=_principal(request),
        )
        return Response(operations_svc.dispute_payload(dispute))


class DisputeResolveView(APIView):
    permission_classes = [IsDevice, IsPropertyOpsWriter]

    def post(self, request, dispute_id):
        dispute = get_object_or_404(PropertyDispute, pk=dispute_id)
        ser = ResolveDisputeSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        dispute = operations_svc.resolve_dispute(
            dispute=dispute,
            actor=_principal(request),
            resolution=ser.validated_data["resolution"],
            approve=ser.validated_data.get("approve", True),
        )
        return Response(operations_svc.dispute_payload(dispute))


class OpsConsoleView(APIView):
    """Dedicated ops console — dashboard, moderation, disputes, audit in one call."""

    permission_classes = [IsDevice, IsPropertyOpsReader]

    def get(self, request):
        region = request.query_params.get("region", "")
        limit = int(request.query_params.get("limit", 30))
        return Response(operations_svc.ops_console_bundle(region=region, limit=limit))
