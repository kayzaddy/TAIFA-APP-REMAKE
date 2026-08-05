"""Winga Brokerage Platform API — REST + OpenAPI."""
from __future__ import annotations

from django.db.models import Avg, Count, Sum
from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from payments.auth import IsDevice

from . import ai as winga_ai
from . import services
from .models import (
    BrokerageDeal,
    BrokerageDomain,
    Category,
    CommissionEvent,
    CommissionRule,
    Favorite,
    Lead,
    Offering,
    ProviderProfile,
    Quotation,
    Review,
    VerificationStatus,
    WingaProfile,
)
from .serializers import (
    BrokerageDealSerializer,
    BrokerageDomainSerializer,
    CategorySerializer,
    CommissionEventSerializer,
    CommissionRuleSerializer,
    FavoriteSerializer,
    LeadSerializer,
    OfferingSerializer,
    ProviderProfileSerializer,
    QuotationSerializer,
    ReviewSerializer,
    WingaProfileSerializer,
)
from .settlement import SettlementError, collect_deal_payment, settle_commissions


def _principal(request) -> str:
    auth = getattr(request, "auth", None)
    if auth is not None and getattr(auth, "owner", None):
        return auth.owner
    user = getattr(request, "user", None)
    if user is not None and getattr(user, "is_authenticated", False):
        return str(user.pk)
    return "anonymous"


class DomainListView(APIView):
    permission_classes = [IsDevice]

    @extend_schema(responses=BrokerageDomainSerializer(many=True))
    def get(self, request):
        qs = BrokerageDomain.objects.filter(active=True)
        return Response(BrokerageDomainSerializer(qs, many=True).data)


class CategoryListView(APIView):
    permission_classes = [IsDevice]

    @extend_schema(responses=CategorySerializer(many=True))
    def get(self, request):
        domain = request.query_params.get("domain")
        qs = Category.objects.filter(active=True)
        if domain:
            qs = qs.filter(domain__code=domain)
        return Response(CategorySerializer(qs, many=True).data)


class WingaProfileListCreateView(APIView):
    permission_classes = [IsDevice]

    @extend_schema(responses=WingaProfileSerializer(many=True))
    def get(self, request):
        qs = WingaProfile.objects.filter(active=True)
        mine = request.query_params.get("mine")
        if mine:
            qs = qs.filter(principal=_principal(request))
        return Response(WingaProfileSerializer(qs[:100], many=True).data)

    @extend_schema(request=WingaProfileSerializer, responses=WingaProfileSerializer)
    def post(self, request):
        data = dict(request.data)
        data["principal"] = _principal(request)
        ser = WingaProfileSerializer(data=data)
        ser.is_valid(raise_exception=True)
        obj = WingaProfile.objects.create(**ser.validated_data)
        return Response(WingaProfileSerializer(obj).data, status=status.HTTP_201_CREATED)


class WingaVerifyView(APIView):
    """Ops/admin verification hook — marks Winga verified after KYC."""

    permission_classes = [IsDevice]

    def post(self, request, pk):
        obj = WingaProfile.objects.get(pk=pk)
        obj.verification_status = VerificationStatus.VERIFIED
        obj.kyc_ref = str(request.data.get("kyc_ref") or obj.kyc_ref or f"KYC-{obj.id}")
        obj.save(update_fields=["verification_status", "kyc_ref", "updated_at"])
        return Response(WingaProfileSerializer(obj).data)


class ProviderListCreateView(APIView):
    permission_classes = [IsDevice]

    @extend_schema(responses=ProviderProfileSerializer(many=True))
    def get(self, request):
        qs = ProviderProfile.objects.filter(active=True)
        if request.query_params.get("mine"):
            qs = qs.filter(principal=_principal(request))
        return Response(ProviderProfileSerializer(qs[:100], many=True).data)

    @extend_schema(request=ProviderProfileSerializer, responses=ProviderProfileSerializer)
    def post(self, request):
        data = dict(request.data)
        data["principal"] = _principal(request)
        ser = ProviderProfileSerializer(data=data)
        ser.is_valid(raise_exception=True)
        obj = ProviderProfile.objects.create(**{k: v for k, v in ser.validated_data.items() if k != "merchant"})
        return Response(ProviderProfileSerializer(obj).data, status=status.HTTP_201_CREATED)


class ProviderVerifyView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, pk):
        obj = ProviderProfile.objects.get(pk=pk)
        obj.verification_status = VerificationStatus.VERIFIED
        obj.kyb_ref = str(request.data.get("kyb_ref") or obj.kyb_ref or f"KYB-{obj.id}")
        obj.save(update_fields=["verification_status", "kyb_ref", "updated_at"])
        return Response(ProviderProfileSerializer(obj).data)


class OfferingListCreateView(APIView):
    permission_classes = [IsDevice]

    @extend_schema(responses=OfferingSerializer(many=True))
    def get(self, request):
        qs = Offering.objects.filter(active=True).select_related("provider", "domain")
        domain = request.query_params.get("domain")
        kind = request.query_params.get("kind")
        q = request.query_params.get("q")
        if domain:
            qs = qs.filter(domain__code=domain)
        if kind:
            qs = qs.filter(kind=kind)
        if q:
            qs = qs.filter(title__icontains=q)
        return Response(OfferingSerializer(qs[:200], many=True).data)

    @extend_schema(request=OfferingSerializer, responses=OfferingSerializer)
    def post(self, request):
        ser = OfferingSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        obj = Offering.objects.create(**ser.validated_data)
        return Response(OfferingSerializer(obj).data, status=status.HTTP_201_CREATED)


class LeadListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = Lead.objects.all()
        winga_id = request.query_params.get("winga")
        if winga_id:
            qs = qs.filter(winga_id=winga_id)
        else:
            qs = qs.filter(winga__principal=_principal(request))
        return Response(LeadSerializer(qs[:100], many=True).data)

    def post(self, request):
        winga = WingaProfile.objects.get(pk=request.data["winga"])
        domain = BrokerageDomain.objects.get(pk=request.data["domain"])
        offering = None
        if request.data.get("offering"):
            offering = Offering.objects.get(pk=request.data["offering"])
        lead = services.create_lead(
            winga=winga,
            customer_principal=str(request.data.get("customer_principal") or _principal(request)),
            domain=domain,
            title=str(request.data.get("title") or "Lead"),
            offering=offering,
            notes=str(request.data.get("notes") or ""),
        )
        return Response(LeadSerializer(lead).data, status=status.HTTP_201_CREATED)


class QuotationCreateView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        lead = Lead.objects.get(pk=request.data["lead"])
        provider = ProviderProfile.objects.get(pk=request.data["provider"])
        quote = services.create_quotation(
            lead=lead,
            provider=provider,
            amount_minor=int(request.data["amount_minor"]),
            currency=str(request.data.get("currency") or "TZS"),
            line_items=request.data.get("line_items") or [],
            notes=str(request.data.get("notes") or ""),
        )
        return Response(QuotationSerializer(quote).data, status=status.HTTP_201_CREATED)


class DealListCreateView(APIView):
    permission_classes = [IsDevice]

    @extend_schema(operation_id="winga_deals_list")
    def get(self, request):
        qs = BrokerageDeal.objects.select_related("domain", "winga", "provider")
        role = request.query_params.get("role", "customer")
        principal = _principal(request)
        if role == "winga":
            qs = qs.filter(winga__principal=principal)
        elif role == "provider":
            qs = qs.filter(provider__principal=principal)
        else:
            qs = qs.filter(customer_principal=principal)
        return Response(BrokerageDealSerializer(qs[:100], many=True).data)

    def post(self, request):
        try:
            deal = services.open_deal(
                winga=WingaProfile.objects.get(pk=request.data["winga"]),
                provider=ProviderProfile.objects.get(pk=request.data["provider"]),
                customer_principal=str(request.data.get("customer_principal") or _principal(request)),
                domain=BrokerageDomain.objects.get(pk=request.data["domain"]),
                amount_minor=int(request.data.get("amount_minor") or 0),
                currency=str(request.data.get("currency") or "TZS"),
                offering=Offering.objects.filter(pk=request.data["offering"]).first()
                if request.data.get("offering")
                else None,
                lead=Lead.objects.filter(pk=request.data["lead"]).first() if request.data.get("lead") else None,
                quotation=Quotation.objects.filter(pk=request.data["quotation"]).first()
                if request.data.get("quotation")
                else None,
                booking=request.data.get("booking") or {},
                actor=_principal(request),
            )
        except services.WingaError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_400_BAD_REQUEST)
        return Response(BrokerageDealSerializer(deal).data, status=status.HTTP_201_CREATED)


class DealDetailView(APIView):
    permission_classes = [IsDevice]

    @extend_schema(operation_id="winga_deals_retrieve")
    def get(self, request, pk):
        deal = BrokerageDeal.objects.get(pk=pk)
        return Response(BrokerageDealSerializer(deal).data)


class DealAdvanceView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, pk):
        deal = BrokerageDeal.objects.select_related("domain").get(pk=pk)
        try:
            deal = services.advance_deal(
                deal=deal,
                to_stage=str(request.data.get("stage") or ""),
                actor=_principal(request),
                note=str(request.data.get("note") or ""),
            )
        except services.WingaError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_400_BAD_REQUEST)
        return Response(BrokerageDealSerializer(deal).data)


class DealPayView(APIView):
    """Ledger-backed payment — never AI-authorized."""

    permission_classes = [IsDevice]

    def post(self, request, pk):
        deal = BrokerageDeal.objects.select_related("provider", "winga", "domain").get(pk=pk)
        idem = request.headers.get("Idempotency-Key") or request.data.get("idempotency_key")
        if not idem:
            return Response({"detail": "Idempotency-Key required"}, status=status.HTTP_400_BAD_REQUEST)
        try:
            deal = collect_deal_payment(deal=deal, actor=_principal(request), idempotency_key=str(idem))
        except SettlementError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_400_BAD_REQUEST)
        return Response(BrokerageDealSerializer(deal).data)


class DealSettleCommissionView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, pk):
        deal = BrokerageDeal.objects.select_related("winga", "domain").get(pk=pk)
        try:
            events = settle_commissions(deal=deal, actor=_principal(request))
        except SettlementError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_400_BAD_REQUEST)
        deal.refresh_from_db()
        return Response(
            {
                "deal": BrokerageDealSerializer(deal).data,
                "commissions": CommissionEventSerializer(events, many=True).data,
            }
        )


class CommissionRuleListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        return Response(CommissionRuleSerializer(CommissionRule.objects.filter(active=True)[:100], many=True).data)

    def post(self, request):
        ser = CommissionRuleSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        obj = CommissionRule.objects.create(**ser.validated_data)
        return Response(CommissionRuleSerializer(obj).data, status=status.HTTP_201_CREATED)


class CommissionEventListView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = CommissionEvent.objects.select_related("deal", "winga")
        if request.query_params.get("winga"):
            qs = qs.filter(winga_id=request.query_params["winga"])
        if request.query_params.get("deal"):
            qs = qs.filter(deal_id=request.query_params["deal"])
        return Response(CommissionEventSerializer(qs[:100], many=True).data)


class ReviewCreateView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        deal = BrokerageDeal.objects.get(pk=request.data["deal"])
        try:
            review = services.submit_review(
                deal=deal,
                author_principal=_principal(request),
                subject_type=str(request.data["subject_type"]),
                subject_id=request.data["subject_id"],
                rating_e4=int(request.data["rating_e4"]),
                comment=str(request.data.get("comment") or ""),
            )
        except services.WingaError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_400_BAD_REQUEST)
        return Response(ReviewSerializer(review).data, status=status.HTTP_201_CREATED)


class FavoriteListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = Favorite.objects.filter(owner_principal=_principal(request))
        return Response(FavoriteSerializer(qs[:100], many=True).data)

    def post(self, request):
        offering = Offering.objects.get(pk=request.data["offering"])
        fav, _ = Favorite.objects.get_or_create(
            owner_principal=_principal(request),
            offering=offering,
        )
        return Response(FavoriteSerializer(fav).data, status=status.HTTP_201_CREATED)


class AssistView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        try:
            result = winga_ai.assist(
                capability=str(request.data.get("capability") or "recommendations"),
                principal=_principal(request),
                payload=request.data.get("payload") or {},
            )
        except winga_ai.WingaAiError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_400_BAD_REQUEST)
        return Response(result)


class AnalyticsSummaryView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        deals = BrokerageDeal.objects.all()
        commissions = CommissionEvent.objects.filter(status="settled")
        by_domain = list(
            deals.values("domain__code").annotate(count=Count("id"), gmv=Sum("amount_minor")).order_by("-gmv")[:20]
        )
        return Response(
            {
                "deals_total": deals.count(),
                "leads_total": Lead.objects.count(),
                "offerings_total": Offering.objects.filter(active=True).count(),
                "wingas_verified": WingaProfile.objects.filter(
                    verification_status=VerificationStatus.VERIFIED
                ).count(),
                "providers_verified": ProviderProfile.objects.filter(
                    verification_status=VerificationStatus.VERIFIED
                ).count(),
                "commission_settled_minor": commissions.aggregate(s=Sum("commission_minor"))["s"] or 0,
                "gmv_by_domain": by_domain,
                "avg_provider_reputation_e4": ProviderProfile.objects.aggregate(a=Avg("reputation_score_e4"))["a"],
                "avg_winga_reputation_e4": WingaProfile.objects.aggregate(a=Avg("reputation_score_e4"))["a"],
            }
        )
