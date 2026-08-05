"""Financial statements from the ledger (OLTP snapshot → report payload).

Dashboards use projections; formal statements are generated on demand and stored
as payloads (not live ledger joins on every page view).
"""
from __future__ import annotations

from collections import defaultdict
from dataclasses import dataclass

from payments.models import LedgerAccount, LedgerAccountType, Posting, PostingDirection


@dataclass
class TrialBalanceRow:
    account_id: str
    account_type: str
    debit_minor: int
    credit_minor: int


def trial_balance(*, currency: str) -> list[TrialBalanceRow]:
    rows: dict[str, TrialBalanceRow] = {}
    for p in Posting.objects.filter(currency=currency).select_related("account"):
        row = rows.get(p.account_id)
        if row is None:
            row = TrialBalanceRow(p.account_id, p.account.account_type, 0, 0)
            rows[p.account_id] = row
        if p.direction == PostingDirection.DEBIT:
            row.debit_minor += p.amount_minor
        else:
            row.credit_minor += p.amount_minor
    return sorted(rows.values(), key=lambda r: r.account_id)


def balance_sheet(*, currency: str) -> dict:
    tb = trial_balance(currency=currency)
    assets = liabilities = equity_ish = 0
    asset_types = {
        LedgerAccountType.TREASURY,
        LedgerAccountType.PROVIDER_SETTLEMENT,
        LedgerAccountType.SETTLEMENT_PENDING,
        LedgerAccountType.CASH_IN_TRANSIT,
        LedgerAccountType.EXTERNAL_BANK,
        LedgerAccountType.EXTERNAL_MOBILE_MONEY,
        LedgerAccountType.CRYPTO_VAULT,
        LedgerAccountType.SUSPENSE,
        LedgerAccountType.CHARGEBACK_EXPENSE,
        LedgerAccountType.FRAUD_LOSS,
        LedgerAccountType.FX_LOSS,
    }
    liability_types = {
        LedgerAccountType.USER_WALLET,
        LedgerAccountType.FUNDS_ON_HOLD,
        LedgerAccountType.MERCHANT_PAYABLE,
        LedgerAccountType.TAX_PAYABLE,
        LedgerAccountType.PROVIDER_PAYABLE,
        LedgerAccountType.FEES_PAYABLE,
        LedgerAccountType.CHARGEBACK_RESERVE,
        LedgerAccountType.LIQUIDITY_RESERVE,
    }
    for row in tb:
        net = row.debit_minor - row.credit_minor
        if row.account_type in asset_types:
            assets += net
        elif row.account_type in liability_types:
            liabilities += -net  # credit-normal
        else:
            equity_ish += -net
    return {
        "currency": currency,
        "assets_minor": assets,
        "liabilities_minor": liabilities,
        "equity_and_pnl_minor": equity_ish,
        "balanced": assets == liabilities + equity_ish,
    }


def profit_and_loss(*, currency: str) -> dict:
    revenue = expense = 0
    for p in Posting.objects.filter(currency=currency).select_related("account"):
        if p.account.account_type in {
            LedgerAccountType.FEE_INCOME,
            LedgerAccountType.COMMISSION_INCOME,
            LedgerAccountType.FX_GAIN,
        }:
            revenue += p.amount_minor if p.direction == PostingDirection.CREDIT else -p.amount_minor
        if p.account.account_type in {
            LedgerAccountType.CHARGEBACK_EXPENSE,
            LedgerAccountType.FRAUD_LOSS,
            LedgerAccountType.FX_LOSS,
        }:
            expense += p.amount_minor if p.direction == PostingDirection.DEBIT else -p.amount_minor
    return {
        "currency": currency,
        "revenue_minor": revenue,
        "expense_minor": expense,
        "net_income_minor": revenue - expense,
    }


def cash_flow(*, currency: str) -> dict:
    """Simplified: net movement on treasury + external bank + provider settlement."""
    by_type: dict[str, int] = defaultdict(int)
    for p in Posting.objects.filter(
        currency=currency,
        account__account_type__in=[
            LedgerAccountType.TREASURY,
            LedgerAccountType.EXTERNAL_BANK,
            LedgerAccountType.PROVIDER_SETTLEMENT,
            LedgerAccountType.CASH_IN_TRANSIT,
        ],
    ).select_related("account"):
        signed = p.amount_minor if p.direction == PostingDirection.DEBIT else -p.amount_minor
        by_type[p.account.account_type] += signed
    return {"currency": currency, "by_account_type": dict(by_type)}
