"""Enterprise Financial Platform HTTP API (v1)."""
from datetime import timedelta

from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import status
from drf_spectacular.utils import extend_schema
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from payments.auth import DeviceTokenAuthentication, IsDevice
from payments.engine import default_engine
from payments.money import Currency, Money
from payments.models import Transaction

from . import approval, event_bus, financial_reports, regulatory
from .metrics import PLATFORM_CAPTURES, refresh_enterprise_metrics
from .models import (
    ChargebackCase,
    Merchant,
    MerchantSettlement,
    MerchantStatus,
    TreasuryBankAccount,
    TreasuryTransfer,
)
from .orchestrator import PlatformContext, PlatformError, default_platform
from .projections import refresh_executive, refresh_finance, refresh_liquidity, refresh_merchant


def _ctx(request) -> PlatformContext:
    actor = getattr(getattr(request, "user", None), "owner", None) or request.headers.get(
        "X-Actor", "system"
    )
    return PlatformContext(actor=str(actor), ip=request.META.get("REMOTE_ADDR"))


@extend_schema(exclude=True)
class MerchantRegisterView(APIView):
    authentication_classes = []
    permission_classes = [AllowAny]

    def post(self, request):
        code = request.data.get("code", "").strip()
        legal_name = request.data.get("legal_name", "").strip()
        if not code or not legal_name:
            return Response({"detail": "code and legal_name required"}, status=400)
        m, created = Merchant.objects.get_or_create(
            code=code,
            defaults={
                "legal_name": legal_name,
                "trading_name": request.data.get("trading_name", legal_name),
                "status": MerchantStatus.ACTIVE,
                "sector": request.data.get("sector", ""),
                "fee_bps": int(request.data.get("fee_bps", 150)),
                "bank_code": request.data.get("bank_code", "primary"),
            },
        )
        return Response(
            {"id": str(m.id), "code": m.code, "status": m.status, "created": created},
            status=201 if created else 200,
        )


@extend_schema(exclude=True)
class MerchantCaptureView(APIView):
    authentication_classes = [DeviceTokenAuthentication]
    permission_classes = [AllowAny]

    def post(self, request, merchant_id):
        merchant = get_object_or_404(Merchant, pk=merchant_id)
        try:
            amount = Money(int(request.data["amount_minor"]), Currency.from_code(request.data.get("currency", "TZS")))
        except Exception:
            return Response({"detail": "amount_minor required"}, status=400)
        key = request.headers.get("Idempotency-Key") or request.data.get("idempotency_key")
        if not key:
            return Response({"detail": "Idempotency-Key required"}, status=400)
        owner = getattr(request.user, "owner", None) or request.data.get("owner", "")
        try:
            txn = default_platform().capture_merchant_payment(
                ctx=_ctx(request),
                merchant=merchant,
                payer_owner=owner,
                amount=amount,
                idempotency_key=key,
            )
            PLATFORM_CAPTURES.inc()
            return Response(
                {"transaction_id": str(txn.id), "status": txn.status, "ledger_entry_id": str(txn.ledger_entry_id)},
                status=201,
            )
        except PlatformError as exc:
            return Response({"detail": str(exc)}, status=400)


@extend_schema(exclude=True)
class SettlementCreateView(APIView):
    authentication_classes = []
    permission_classes = [AllowAny]

    def post(self, request, merchant_id):
        merchant = get_object_or_404(Merchant, pk=merchant_id)
        amount = Money(int(request.data["amount_minor"]), Currency.from_code(request.data.get("currency", "TZS")))
        key = request.headers.get("Idempotency-Key") or request.data["idempotency_key"]
        now = timezone.now()
        settlement = default_platform().create_settlement(
            ctx=_ctx(request),
            merchant=merchant,
            amount=amount,
            period_start=now - timedelta(days=1),
            period_end=now,
            idempotency_key=key,
            require_approval_above_minor=int(request.data.get("approval_threshold_minor", 50_000_000)),
        )
        return Response(
            {"id": str(settlement.id), "status": settlement.status, "net_minor": settlement.net_minor},
            status=201,
        )


@extend_schema(exclude=True)
class SettlementExecuteView(APIView):
    authentication_classes = []
    permission_classes = [AllowAny]

    def post(self, request, settlement_id):
        settlement = get_object_or_404(MerchantSettlement, pk=settlement_id)
        # If pending approval, allow execute only when approved via approval API first
        if settlement.status == "pending_approval":
            return Response({"detail": "awaiting maker-checker approval"}, status=409)
        try:
            settlement = default_platform().execute_settlement(ctx=_ctx(request), settlement=settlement)
            return Response({"id": str(settlement.id), "status": settlement.status, "statement_ref": settlement.statement_ref})
        except PlatformError as exc:
            return Response({"detail": str(exc)}, status=400)


@extend_schema(exclude=True)
class SettlementCancelView(APIView):
    authentication_classes = []
    permission_classes = [AllowAny]

    def post(self, request, settlement_id):
        settlement = get_object_or_404(MerchantSettlement, pk=settlement_id)
        try:
            settlement = default_platform().cancel_settlement(ctx=_ctx(request), settlement=settlement)
            return Response({"id": str(settlement.id), "status": settlement.status})
        except PlatformError as exc:
            return Response({"detail": str(exc)}, status=400)


@extend_schema(exclude=True)
class ApprovalDecideView(APIView):
    authentication_classes = []
    permission_classes = [AllowAny]

    def post(self, request, approval_id):
        approve = bool(request.data.get("approve", False))
        checker = request.data.get("checker") or request.headers.get("X-Actor", "checker")
        try:
            req = approval.decide(request_id=approval_id, checker=checker, approve=approve, reason=request.data.get("reason", ""))
            if approve and req.action == "settlement.execute":
                settlement = MerchantSettlement.objects.get(pk=req.resource_id)
                settlement.status = "approved"
                settlement.save(update_fields=["status", "updated_at"])
            if approve and req.action == "treasury.transfer":
                transfer = TreasuryTransfer.objects.get(pk=req.resource_id)
                default_platform()._execute_treasury_transfer(ctx=_ctx(request), transfer=transfer)
            return Response({"id": str(req.id), "status": req.status})
        except Exception as exc:
            return Response({"detail": str(exc)}, status=400)


@extend_schema(exclude=True)
class ChargebackOpenView(APIView):
    authentication_classes = []
    permission_classes = [AllowAny]

    def post(self, request):
        merchant = get_object_or_404(Merchant, pk=request.data["merchant_id"])
        original = get_object_or_404(Transaction, pk=request.data["transaction_id"])
        amount = Money(int(request.data["amount_minor"]), Currency.from_code(request.data.get("currency", "TZS")))
        case = default_platform().open_chargeback(
            ctx=_ctx(request),
            merchant=merchant,
            original=original,
            amount=amount,
            idempotency_key=request.data["idempotency_key"],
            reason_code=request.data.get("reason_code", ""),
        )
        return Response({"id": str(case.id), "status": case.status}, status=201)


@extend_schema(exclude=True)
class ChargebackTransitionView(APIView):
    authentication_classes = []
    permission_classes = [AllowAny]

    def post(self, request, case_id):
        case = get_object_or_404(ChargebackCase, pk=case_id)
        try:
            case = default_platform().transition_chargeback(
                ctx=_ctx(request),
                case=case,
                to_status=request.data["status"],
                note=request.data.get("note", ""),
                evidence=request.data.get("evidence"),
            )
            return Response({"id": str(case.id), "status": case.status})
        except PlatformError as exc:
            return Response({"detail": str(exc)}, status=400)


@extend_schema(exclude=True)
class TreasuryAccountView(APIView):
    authentication_classes = []
    permission_classes = [AllowAny]

    def post(self, request):
        acc = TreasuryBankAccount.objects.create(
            code=request.data["code"],
            bank_name=request.data.get("bank_name", "Bank"),
            account_number_masked=request.data.get("account_number_masked", "****"),
            kind=request.data.get("kind", "operating"),
            currency=request.data.get("currency", "TZS"),
            ledger_bank_code=request.data.get("ledger_bank_code", request.data["code"]),
        )
        return Response({"id": str(acc.id), "code": acc.code}, status=201)

    def get(self, request):
        rows = list(TreasuryBankAccount.objects.filter(is_active=True).values("id", "code", "kind", "currency"))
        return Response({"accounts": rows})


@extend_schema(exclude=True)
class TreasuryTransferView(APIView):
    authentication_classes = []
    permission_classes = [AllowAny]

    def post(self, request):
        src = get_object_or_404(TreasuryBankAccount, code=request.data["from_code"])
        dst = get_object_or_404(TreasuryBankAccount, code=request.data["to_code"])
        transfer = TreasuryTransfer.objects.create(
            from_account=src,
            to_account=dst,
            amount_minor=int(request.data["amount_minor"]),
            currency=request.data.get("currency", "TZS"),
            idempotency_key=request.data["idempotency_key"],
            narrative=request.data.get("narrative", ""),
        )
        transfer = default_platform().treasury_transfer(
            ctx=_ctx(request),
            transfer=transfer,
            require_approval_above_minor=int(request.data.get("approval_threshold_minor", 100_000_000)),
        )
        return Response({"id": str(transfer.id), "status": transfer.status}, status=201)


@extend_schema(exclude=True)
class ReportsView(APIView):
    authentication_classes = []
    permission_classes = [AllowAny]

    def get(self, request, report_type):
        currency = request.query_params.get("currency", "TZS")
        if report_type == "trial-balance":
            rows = financial_reports.trial_balance(currency=currency)
            return Response({"rows": [r.__dict__ for r in rows]})
        if report_type == "balance-sheet":
            return Response(financial_reports.balance_sheet(currency=currency))
        if report_type == "pnl":
            return Response(financial_reports.profit_and_loss(currency=currency))
        if report_type == "cash-flow":
            return Response(financial_reports.cash_flow(currency=currency))
        if report_type == "bot-daily":
            rep = regulatory.generate_bot_daily()
            return Response({"id": str(rep.id), "payload": rep.payload})
        if report_type == "auditor-pack":
            rep = regulatory.generate_auditor_pack(currency=currency)
            return Response({"id": str(rep.id), "payload": rep.payload})
        return Response({"detail": "unknown report"}, status=404)


@extend_schema(exclude=True)
class DashboardView(APIView):
    authentication_classes = []
    permission_classes = [AllowAny]

    def get(self, request, kind):
        currency = request.query_params.get("currency", "TZS")
        if kind == "finance":
            obj = refresh_finance(currency)
            return Response(
                {
                    "currency": obj.currency,
                    "fee_income_mtd_minor": obj.fee_income_mtd_minor,
                    "commission_mtd_minor": obj.commission_mtd_minor,
                    "tax_payable_minor": obj.tax_payable_minor,
                }
            )
        if kind == "executive":
            obj = refresh_executive(currency)
            return Response(
                {
                    "currency": obj.currency,
                    "gmv_mtd_minor": obj.gmv_mtd_minor,
                    "revenue_mtd_minor": obj.revenue_mtd_minor,
                    "active_merchants": obj.active_merchants,
                    "settlement_success_rate_e4": obj.settlement_success_rate_e4,
                }
            )
        if kind == "liquidity":
            snap = refresh_liquidity(currency)
            return Response(
                {
                    "currency": snap.currency,
                    "treasury_minor": snap.treasury_minor,
                    "provider_settlement_minor": snap.provider_settlement_minor,
                    "merchant_payable_minor": snap.merchant_payable_minor,
                    "reserve_minor": snap.reserve_minor,
                }
            )
        if kind == "merchant":
            merchant = get_object_or_404(Merchant, code=request.query_params.get("code"))
            obj = refresh_merchant(merchant)
            return Response(
                {
                    "merchant": merchant.code,
                    "payable_minor": obj.payable_minor,
                    "captures_today_minor": obj.captures_today_minor,
                    "settlements_mtd_minor": obj.settlements_mtd_minor,
                    "open_chargebacks": obj.open_chargebacks,
                }
            )
        return Response({"detail": "unknown dashboard"}, status=404)


@extend_schema(exclude=True)
class OutboxDrainView(APIView):
    """Drain outbox to configured webhooks. Requires device auth (ops tooling)."""

    permission_classes = [IsDevice]

    def post(self, request):
        n = event_bus.drain_outbox(limit=int(request.data.get("limit", 100)))
        refresh_enterprise_metrics()
        return Response({"published": n})


@extend_schema(exclude=True)
class MerchantBootstrapWalletView(APIView):
    """Test/helper: ensure payer has wallet (uses payment engine open_wallet only)."""

    authentication_classes = []
    permission_classes = [AllowAny]

    def post(self, request):
        owner = request.data["owner"]
        amount = Money(int(request.data.get("amount_minor", 0)), Currency.TZS)
        if amount.minor_units > 0:
            default_engine().open_wallet(owner, amount)
        return Response({"owner": owner, "ok": True})
