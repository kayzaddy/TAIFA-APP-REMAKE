"""Reporting projections — read models. Never query hot ledger joins in dashboards."""
from __future__ import annotations

from django.db.models import Count, Sum
from django.utils import timezone

from payments import journal, ledger
from payments.models import LedgerAccountType, LedgerEntryKind, Posting, Transaction, TransactionType
from payments.money import Currency

from .models import (
    ChargebackCase,
    ChargebackStatus,
    ExecutiveDashboardProjection,
    FinanceDashboardProjection,
    LiquiditySnapshot,
    Merchant,
    MerchantDashboardProjection,
    MerchantSettlement,
    MerchantSettlementStatus,
    MerchantStatus,
)


def refresh_merchant(merchant: Merchant) -> MerchantDashboardProjection:
    cur = Currency.from_code(merchant.settlement_currency)
    payable = ledger.balance_of(journal.merchant_payable(str(merchant.id), cur))
    today = timezone.now().replace(hour=0, minute=0, second=0, microsecond=0)
    captures = (
        Transaction.objects.filter(
            type=TransactionType.MERCHANT_PAYMENT,
            counterparty=merchant.code,
            status="succeeded",
            created_at__gte=today,
        ).aggregate(s=Sum("amount_minor"))["s"]
        or 0
    )
    month_start = today.replace(day=1)
    settlements = (
        MerchantSettlement.objects.filter(
            merchant=merchant,
            status=MerchantSettlementStatus.COMPLETED,
            completed_at__gte=month_start,
        ).aggregate(s=Sum("net_minor"))["s"]
        or 0
    )
    open_cbs = ChargebackCase.objects.filter(merchant=merchant).exclude(
        status__in=[ChargebackStatus.WON, ChargebackStatus.LOST, ChargebackStatus.REVERSED]
    ).count()
    obj, _ = MerchantDashboardProjection.objects.update_or_create(
        merchant=merchant,
        defaults={
            "currency": cur.code,
            "payable_minor": payable.minor_units,
            "captures_today_minor": captures,
            "settlements_mtd_minor": settlements,
            "open_chargebacks": open_cbs,
        },
    )
    return obj


def refresh_finance(currency_code: str) -> FinanceDashboardProjection:
    month_start = timezone.now().replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    fee = (
        Posting.objects.filter(
            account__account_type=LedgerAccountType.FEE_INCOME,
            currency=currency_code,
            created_at__gte=month_start,
        ).aggregate(s=Sum("amount_minor"))["s"]
        or 0
    )
    commission = (
        Posting.objects.filter(
            account__account_type=LedgerAccountType.COMMISSION_INCOME,
            currency=currency_code,
            created_at__gte=month_start,
        ).aggregate(s=Sum("amount_minor"))["s"]
        or 0
    )
    tax = ledger.balance_of(journal.tax_payable(Currency.from_code(currency_code))).minor_units
    cb_exp = (
        Posting.objects.filter(
            account__account_type=LedgerAccountType.CHARGEBACK_EXPENSE,
            currency=currency_code,
            created_at__gte=month_start,
        ).aggregate(s=Sum("amount_minor"))["s"]
        or 0
    )
    obj, _ = FinanceDashboardProjection.objects.update_or_create(
        currency=currency_code,
        defaults={
            "fee_income_mtd_minor": fee,
            "commission_mtd_minor": commission,
            "tax_payable_minor": tax,
            "chargeback_expense_mtd_minor": cb_exp,
        },
    )
    return obj


def refresh_executive(currency_code: str) -> ExecutiveDashboardProjection:
    month_start = timezone.now().replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    gmv = (
        Transaction.objects.filter(
            type=TransactionType.MERCHANT_PAYMENT,
            currency=currency_code,
            status="succeeded",
            created_at__gte=month_start,
        ).aggregate(s=Sum("amount_minor"))["s"]
        or 0
    )
    revenue = (
        Posting.objects.filter(
            account__account_type__in=[LedgerAccountType.FEE_INCOME, LedgerAccountType.COMMISSION_INCOME],
            currency=currency_code,
            created_at__gte=month_start,
        ).aggregate(s=Sum("amount_minor"))["s"]
        or 0
    )
    active = Merchant.objects.filter(status=MerchantStatus.ACTIVE).count()
    total_s = MerchantSettlement.objects.filter(created_at__gte=month_start).count() or 1
    ok_s = MerchantSettlement.objects.filter(
        status=MerchantSettlementStatus.COMPLETED, created_at__gte=month_start
    ).count()
    obj, _ = ExecutiveDashboardProjection.objects.update_or_create(
        currency=currency_code,
        defaults={
            "gmv_mtd_minor": gmv,
            "revenue_mtd_minor": revenue,
            "active_merchants": active,
            "settlement_success_rate_e4": int(ok_s * 10000 / total_s),
        },
    )
    return obj


def refresh_liquidity(currency_code: str) -> LiquiditySnapshot:
    cur = Currency.from_code(currency_code)
    snap = LiquiditySnapshot.objects.create(
        currency=currency_code,
        treasury_minor=ledger.balance_of(journal.treasury(cur)).minor_units,
        provider_settlement_minor=ledger.balance_of(journal.settlement(cur)).minor_units,
        merchant_payable_minor=sum(
            ledger.balance_of(journal.merchant_payable(str(m.id), cur)).minor_units
            for m in Merchant.objects.filter(status=MerchantStatus.ACTIVE)[:500]
        ),
        reserve_minor=ledger.balance_of(journal.liquidity_reserve(cur)).minor_units
        + ledger.balance_of(journal.chargeback_reserve(cur)).minor_units,
        float_minor=ledger.balance_of(journal.treasury(cur)).minor_units,
    )
    return snap
