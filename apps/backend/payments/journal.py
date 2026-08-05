"""Journal recipes — the only place money-movement posting patterns are defined.

The Payment Engine calls these helpers; views never build PostingSpecs. Every
helper goes through `ledger.post_entry`, which enforces double-entry balance.
"""
from __future__ import annotations

from . import ledger
from .models import (
    LedgerAccountType,
    LedgerEntry,
    LedgerEntryKind,
    PostingDirection,
    Transaction,
)
from .money import Currency, Money

SUSPENSE_ID = "house:suspense:{cur}"
SETTLEMENT_ID = "house:provider-settlement:{cur}"
FEE_INCOME_ID = "house:fee-income:{cur}"
TREASURY_ID = "house:treasury:{cur}"


def user_wallet(owner: str, currency: Currency):
    return ledger.get_account(
        f"user:{owner}:wallet:{currency.code}",
        LedgerAccountType.USER_WALLET,
        currency,
        owner,
    )


def user_hold(owner: str, currency: Currency):
    return ledger.get_account(
        f"user:{owner}:hold:{currency.code}",
        LedgerAccountType.FUNDS_ON_HOLD,
        currency,
        owner,
    )


def house(template: str, account_type: str, currency: Currency):
    return ledger.get_account(template.format(cur=currency.code), account_type, currency)


def settlement(currency: Currency):
    return house(SETTLEMENT_ID, LedgerAccountType.PROVIDER_SETTLEMENT, currency)


def fee_income(currency: Currency):
    return house(FEE_INCOME_ID, LedgerAccountType.FEE_INCOME, currency)


def suspense(currency: Currency):
    return house(SUSPENSE_ID, LedgerAccountType.SUSPENSE, currency)


def treasury(currency: Currency):
    return house(TREASURY_ID, LedgerAccountType.TREASURY, currency)


def merchant_payable(merchant_id: str, currency: Currency):
    return ledger.get_account(
        f"merchant:{merchant_id}:payable:{currency.code}",
        LedgerAccountType.MERCHANT_PAYABLE,
        currency,
        merchant_id,
    )


def tax_payable(currency: Currency):
    return house("house:tax-payable:{cur}", LedgerAccountType.TAX_PAYABLE, currency)


def commission_income(currency: Currency):
    return house("house:commission-income:{cur}", LedgerAccountType.COMMISSION_INCOME, currency)


def chargeback_expense(currency: Currency):
    return house("house:chargeback-expense:{cur}", LedgerAccountType.CHARGEBACK_EXPENSE, currency)


def chargeback_reserve(currency: Currency):
    return house("house:chargeback-reserve:{cur}", LedgerAccountType.CHARGEBACK_RESERVE, currency)


def liquidity_reserve(currency: Currency):
    return house("house:liquidity-reserve:{cur}", LedgerAccountType.LIQUIDITY_RESERVE, currency)


def cash_in_transit(currency: Currency):
    return house("house:cash-in-transit:{cur}", LedgerAccountType.CASH_IN_TRANSIT, currency)


def external_bank(bank_code: str, currency: Currency):
    return ledger.get_account(
        f"bank:{bank_code}:external:{currency.code}",
        LedgerAccountType.EXTERNAL_BANK,
        currency,
    )


def post_merchant_capture(
    txn: Transaction,
    *,
    payer_owner: str,
    merchant_id: str,
    amount: Money,
    fee: Money,
    tax: Money,
    commission: Money,
) -> LedgerEntry:
    """Customer pays merchant: wallet → merchant payable (+ fee/tax/commission)."""
    cur = amount.currency
    gross = amount + fee + tax + commission
    specs = [
        ledger.PostingSpec.debit(user_wallet(payer_owner, cur), gross),
        ledger.PostingSpec.credit(merchant_payable(merchant_id, cur), amount),
    ]
    if not fee.is_zero:
        specs.append(ledger.PostingSpec.credit(fee_income(cur), fee))
    if not tax.is_zero:
        specs.append(ledger.PostingSpec.credit(tax_payable(cur), tax))
    if not commission.is_zero:
        specs.append(ledger.PostingSpec.credit(commission_income(cur), commission))
    return ledger.post_entry(txn, f"Merchant capture {merchant_id}", specs, kind=LedgerEntryKind.MERCHANT_CAPTURE)


def post_merchant_settlement_payout(
    txn: Transaction,
    *,
    merchant_id: str,
    amount: Money,
    bank_code: str = "primary",
) -> LedgerEntry:
    """Pay merchant: reduce payable, move via cash-in-transit to external bank."""
    cur = amount.currency
    return ledger.post_entry(
        txn,
        f"Merchant settlement {merchant_id}",
        [
            ledger.PostingSpec.debit(merchant_payable(merchant_id, cur), amount),
            ledger.PostingSpec.credit(external_bank(bank_code, cur), amount),
        ],
        kind=LedgerEntryKind.MERCHANT_PAYOUT,
    )


def post_chargeback_open(
    txn: Transaction,
    *,
    merchant_id: str,
    amount: Money,
) -> LedgerEntry:
    """Hold dispute amount from merchant payable into chargeback reserve."""
    cur = amount.currency
    return ledger.post_entry(
        txn,
        f"Chargeback open {merchant_id}",
        [
            ledger.PostingSpec.debit(merchant_payable(merchant_id, cur), amount),
            ledger.PostingSpec.credit(chargeback_reserve(cur), amount),
        ],
        kind=LedgerEntryKind.RESERVE,
    )


def post_chargeback_won(txn: Transaction, *, amount: Money, merchant_id: str) -> LedgerEntry:
    """Merchant wins: return reserve to merchant payable."""
    cur = amount.currency
    return ledger.post_entry(
        txn,
        "Chargeback won — reserve released",
        [
            ledger.PostingSpec.debit(chargeback_reserve(cur), amount),
            ledger.PostingSpec.credit(merchant_payable(merchant_id, cur), amount),
        ],
        kind=LedgerEntryKind.RELEASE,
    )


def post_chargeback_lost(txn: Transaction, *, amount: Money) -> LedgerEntry:
    """Merchant loses: reserve pays the scheme via provider settlement."""
    cur = amount.currency
    return ledger.post_entry(
        txn,
        "Chargeback lost",
        [
            ledger.PostingSpec.debit(chargeback_reserve(cur), amount),
            ledger.PostingSpec.credit(settlement(cur), amount),
        ],
        kind=LedgerEntryKind.CHARGEBACK,
    )


def post_treasury_transfer(
    txn: Transaction,
    *,
    amount: Money,
    from_bank: str,
    to_bank: str,
) -> LedgerEntry:
    """Move float between bank/treasury accounts (both EXTERNAL_BANK or treasury)."""
    cur = amount.currency
    src = treasury(cur) if from_bank == "treasury" else external_bank(from_bank, cur)
    dst = treasury(cur) if to_bank == "treasury" else external_bank(to_bank, cur)
    return ledger.post_entry(
        txn,
        f"Treasury transfer {from_bank}→{to_bank}",
        [
            ledger.PostingSpec.debit(dst, amount),
            ledger.PostingSpec.credit(src, amount),
        ],
        kind=LedgerEntryKind.TREASURY,
    )


def post_liquidity_reserve(txn: Transaction, *, amount: Money) -> LedgerEntry:
    cur = amount.currency
    return ledger.post_entry(
        txn,
        "Liquidity reserve update",
        [
            ledger.PostingSpec.debit(treasury(cur), amount),
            ledger.PostingSpec.credit(liquidity_reserve(cur), amount),
        ],
        kind=LedgerEntryKind.RESERVE,
    )


def post_opening(txn: Transaction, owner: str, amount: Money) -> LedgerEntry:
    cur = amount.currency
    return ledger.post_entry(
        txn,
        "Opening balance",
        [
            ledger.PostingSpec.debit(suspense(cur), amount),
            ledger.PostingSpec.credit(user_wallet(owner, cur), amount),
        ],
        kind=LedgerEntryKind.OPENING,
    )


def post_topup_settle(txn: Transaction, owner: str, amount: Money, description: str) -> LedgerEntry:
    cur = amount.currency
    return ledger.post_entry(
        txn,
        description,
        [
            ledger.PostingSpec.debit(settlement(cur), amount),
            ledger.PostingSpec.credit(user_wallet(owner, cur), amount),
        ],
        kind=LedgerEntryKind.SETTLE,
    )


def post_transfer_settle(
    txn: Transaction, owner: str, amount: Money, fee: Money, description: str
) -> LedgerEntry:
    cur = amount.currency
    total = amount + fee
    specs = [
        ledger.PostingSpec.debit(user_wallet(owner, cur), total),
        ledger.PostingSpec.credit(settlement(cur), amount),
    ]
    if not fee.is_zero:
        specs.append(ledger.PostingSpec.credit(fee_income(cur), fee))
    return ledger.post_entry(txn, description, specs, kind=LedgerEntryKind.SETTLE)


def post_withdrawal_hold(txn: Transaction, owner: str, amount: Money) -> LedgerEntry:
    """Authorize withdrawal: move funds from available wallet to hold."""
    cur = amount.currency
    return ledger.post_entry(
        txn,
        f"Withdrawal hold {txn.id}",
        [
            ledger.PostingSpec.debit(user_wallet(owner, cur), amount),
            ledger.PostingSpec.credit(user_hold(owner, cur), amount),
        ],
        kind=LedgerEntryKind.HOLD,
    )


def post_withdrawal_release(txn: Transaction, owner: str, amount: Money, reason: str) -> LedgerEntry:
    """Return held funds to the wallet (reject / fail after approve)."""
    cur = amount.currency
    return ledger.post_entry(
        txn,
        f"Withdrawal release ({reason})",
        [
            ledger.PostingSpec.debit(user_hold(owner, cur), amount),
            ledger.PostingSpec.credit(user_wallet(owner, cur), amount),
        ],
        kind=LedgerEntryKind.RELEASE,
    )


def post_withdrawal_settle(txn: Transaction, owner: str, amount: Money) -> LedgerEntry:
    """Payout completed: held funds leave the platform via provider settlement."""
    cur = amount.currency
    return ledger.post_entry(
        txn,
        f"Withdrawal settle to {txn.counterparty}",
        [
            ledger.PostingSpec.debit(user_hold(owner, cur), amount),
            ledger.PostingSpec.credit(settlement(cur), amount),
        ],
        kind=LedgerEntryKind.SETTLE,
    )


def post_refund_for_original(
    refund_txn: Transaction,
    original: Transaction,
    owner: str,
    amount: Money,
    *,
    reverse_fee: Money | None = None,
) -> LedgerEntry:
    """Compensating principal (and optional full fee reverse) for a prior settle."""
    cur = amount.currency
    fee = reverse_fee or Money.zero(cur)

    if original.type == "top_up":
        # Pull funds back out of the wallet toward the rail.
        specs = [
            ledger.PostingSpec.debit(user_wallet(owner, cur), amount),
            ledger.PostingSpec.credit(settlement(cur), amount),
        ]
    else:
        # Send / withdrawal: restore wallet from settlement; claw back fee on full refund.
        if fee.is_zero:
            specs = [
                ledger.PostingSpec.debit(settlement(cur), amount),
                ledger.PostingSpec.credit(user_wallet(owner, cur), amount),
            ]
        else:
            specs = [
                ledger.PostingSpec.debit(settlement(cur), amount),
                ledger.PostingSpec.debit(fee_income(cur), fee),
                ledger.PostingSpec.credit(user_wallet(owner, cur), amount + fee),
            ]

    return ledger.post_entry(
        refund_txn,
        f"Refund of {original.id}",
        specs,
        kind=LedgerEntryKind.REFUND,
        reverses=original.ledger_entry,
    )


def post_reversal(reversal_txn: Transaction, target: LedgerEntry, description: str) -> LedgerEntry:
    """Mirror every posting on `target` with opposite direction (compensating entry)."""
    specs: list[ledger.PostingSpec] = []
    for posting in target.postings.select_related("account").all():
        amount = Money(posting.amount_minor, Currency.from_code(posting.currency))
        if posting.direction == PostingDirection.DEBIT:
            specs.append(ledger.PostingSpec.credit(posting.account, amount))
        else:
            specs.append(ledger.PostingSpec.debit(posting.account, amount))
    return ledger.post_entry(
        reversal_txn,
        description,
        specs,
        kind=LedgerEntryKind.REVERSAL,
        reverses=target,
    )


def entry_of_kind(txn: Transaction, kind: str) -> LedgerEntry | None:
    return txn.ledger_entries.filter(kind=kind).order_by("created_at").first()
