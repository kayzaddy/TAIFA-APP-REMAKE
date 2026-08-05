"""Regulatory / compliance report generators (BoT, tax, AML, auditors)."""
from __future__ import annotations

from datetime import date, datetime, time, timedelta

from django.db.models import Count, Sum
from django.utils import timezone

from payments.models import Transaction, TransactionStatus
from payments.reconciliation import last_reconciliation, run_reconciliation

from .financial_reports import balance_sheet, profit_and_loss, trial_balance
from .models import ChargebackCase, MerchantSettlement, RegulatoryReport


def generate_bot_daily(*, as_of: date | None = None) -> RegulatoryReport:
    day = as_of or timezone.localdate()
    start = timezone.make_aware(datetime.combine(day, time.min))
    end = start + timedelta(days=1)
    txn_stats = (
        Transaction.objects.filter(created_at__gte=start, created_at__lt=end)
        .values("status")
        .annotate(c=Count("id"), amount=Sum("amount_minor"))
    )
    recon = last_reconciliation() or run_reconciliation(record=True)
    payload = {
        "date": str(day),
        "transactions": list(txn_stats),
        "ledger_recon_ok": recon.ok,
        "ledger_breaks": recon.break_count,
        "settlements_completed": MerchantSettlement.objects.filter(
            completed_at__gte=start, completed_at__lt=end, status="completed"
        ).count(),
        "chargebacks_opened": ChargebackCase.objects.filter(created_at__gte=start, created_at__lt=end).count(),
        "trial_balance_tzs_accounts": len(trial_balance(currency="TZS")),
    }
    return RegulatoryReport.objects.create(
        report_type="bot_daily",
        period_start=day,
        period_end=day,
        payload=payload,
    )


def generate_tax_monthly(*, year: int, month: int) -> RegulatoryReport:
    start = date(year, month, 1)
    if month == 12:
        end = date(year + 1, 1, 1) - timedelta(days=1)
    else:
        end = date(year, month + 1, 1) - timedelta(days=1)
    pnl = profit_and_loss(currency="TZS")
    payload = {
        "year": year,
        "month": month,
        "pnl": pnl,
        "balance_sheet": balance_sheet(currency="TZS"),
    }
    return RegulatoryReport.objects.create(
        report_type="tax_monthly",
        period_start=start,
        period_end=end,
        payload=payload,
    )


def generate_aml_sar_stub(*, owner: str, reason: str) -> RegulatoryReport:
    """Suspicious Activity Report shell — investigators attach evidence externally."""
    today = timezone.localdate()
    return RegulatoryReport.objects.create(
        report_type="aml_sar",
        period_start=today,
        period_end=today,
        payload={"owner": owner, "reason": reason, "status": "draft"},
    )


def generate_auditor_pack(*, currency: str = "TZS") -> RegulatoryReport:
    today = timezone.localdate()
    return RegulatoryReport.objects.create(
        report_type="auditor_pack",
        period_start=today.replace(day=1),
        period_end=today,
        payload={
            "trial_balance": [
                {
                    "account_id": r.account_id,
                    "account_type": r.account_type,
                    "debit_minor": r.debit_minor,
                    "credit_minor": r.credit_minor,
                }
                for r in trial_balance(currency=currency)
            ],
            "balance_sheet": balance_sheet(currency=currency),
            "pnl": profit_and_loss(currency=currency),
            "failed_txns": Transaction.objects.filter(status=TransactionStatus.FAILED).count(),
        },
    )
