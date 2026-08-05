"""Double-entry ledger service.

`post_entry` writes an immutable, balanced [LedgerEntry] atomically. It refuses
to write anything whose postings do not net to zero per currency — the single
most important invariant in the payment system (mirror of the Dart
`LedgerEntry` constructor check).
"""
from __future__ import annotations

from dataclasses import dataclass

from django.db import transaction as db_transaction
from django.db.models import Q, Sum

from .models import (
    LedgerAccount,
    LedgerAccountType,
    LedgerEntry,
    LedgerEntryKind,
    Posting,
    PostingDirection,
    Transaction,
)
from .money import Currency, Money

# Accounts whose *natural* balance sits on the credit side (liabilities/income):
# balance = credits - debits. Everything else is an asset (debit-normal).
_CREDIT_NORMAL = {
    LedgerAccountType.USER_WALLET,
    LedgerAccountType.FUNDS_ON_HOLD,
    LedgerAccountType.MERCHANT_PAYABLE,
    LedgerAccountType.TAX_PAYABLE,
    LedgerAccountType.PROVIDER_PAYABLE,
    LedgerAccountType.FEES_PAYABLE,
    LedgerAccountType.FEE_INCOME,
    LedgerAccountType.COMMISSION_INCOME,
    LedgerAccountType.FX_GAIN,
    LedgerAccountType.CHARGEBACK_RESERVE,
    LedgerAccountType.LIQUIDITY_RESERVE,
    LedgerAccountType.EXTERNAL_MOBILE_MONEY,
    LedgerAccountType.EXTERNAL_BANK,
    LedgerAccountType.UNKNOWN_CREDITS,
}


class UnbalancedLedgerEntry(Exception):
    def __init__(self, residuals: dict[str, int]):
        self.residuals = residuals
        super().__init__(f"Postings do not net to zero per currency: {residuals}")


@dataclass(frozen=True)
class PostingSpec:
    account: LedgerAccount
    direction: PostingDirection
    amount: Money

    @staticmethod
    def debit(account: LedgerAccount, amount: Money) -> "PostingSpec":
        return PostingSpec(account, PostingDirection.DEBIT, amount.abs)

    @staticmethod
    def credit(account: LedgerAccount, amount: Money) -> "PostingSpec":
        return PostingSpec(account, PostingDirection.CREDIT, amount.abs)

    @property
    def signed_minor(self) -> int:
        return self.amount.minor_units if self.direction == PostingDirection.DEBIT else -self.amount.minor_units


def _assert_balanced(specs: list[PostingSpec]) -> None:
    residuals: dict[str, int] = {}
    for s in specs:
        code = s.amount.currency.code
        residuals[code] = residuals.get(code, 0) + s.signed_minor
    residuals = {k: v for k, v in residuals.items() if v != 0}
    if residuals:
        raise UnbalancedLedgerEntry(residuals)


@db_transaction.atomic
def post_entry(
    txn: Transaction,
    description: str,
    specs: list[PostingSpec],
    *,
    kind: str = LedgerEntryKind.SETTLE,
    reverses: LedgerEntry | None = None,
    base_currency: Currency | None = None,
) -> LedgerEntry:
    """Atomically write a balanced ledger entry and its postings."""
    _assert_balanced(specs)
    entry = LedgerEntry.objects.create(
        transaction=txn,
        description=description,
        kind=kind,
        reverses=reverses,
    )
    books = base_currency or Currency.TZS
    for s in specs:
        same = s.amount.currency == books
        if same:
            rate_e8 = 100_000_000
            base_minor = s.amount.minor_units
        else:
            rate_e8, base_minor = _fx_to_base(s.amount.minor_units, s.amount.currency, books)
        Posting.objects.create(
            entry=entry,
            account=s.account,
            direction=s.direction,
            amount_minor=s.amount.minor_units,
            currency=s.amount.currency.code,
            base_currency=books.code,
            fx_rate_e8=rate_e8,
            base_amount_minor=base_minor,
        )
    return entry


def _fx_to_base(amount_minor: int, currency: Currency, books: Currency) -> tuple[int, int]:
    """Optional continental FX — falls back to 1:1 if rates unavailable."""
    try:
        from continental.fx import convert_minor

        converted, rate = convert_minor(
            amount_minor=amount_minor,
            from_currency=currency.code,
            to_currency=books.code,
        )
        return rate, converted
    except Exception:
        return 100_000_000, amount_minor


def get_account(account_id: str, account_type: str, currency: Currency, owner: str | None = None) -> LedgerAccount:
    account, _ = LedgerAccount.objects.get_or_create(
        id=account_id,
        defaults={"account_type": account_type, "currency": currency.code, "owner": owner},
    )
    return account


def balance_of(account: LedgerAccount) -> Money:
    """Current balance from the sum of immutable postings, using the account's
    normal balance side (debit-normal for assets, credit-normal for
    liabilities/income)."""
    agg = account.postings.aggregate(
        debit=Sum("amount_minor", filter=Q(direction=PostingDirection.DEBIT)),
        credit=Sum("amount_minor", filter=Q(direction=PostingDirection.CREDIT)),
    )
    debit = agg["debit"] or 0
    credit = agg["credit"] or 0
    currency = Currency.from_code(account.currency)
    minor = (credit - debit) if account.account_type in _CREDIT_NORMAL else (debit - credit)
    return Money(minor, currency)
