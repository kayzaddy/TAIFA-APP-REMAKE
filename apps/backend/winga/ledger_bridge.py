"""Ledger-backed Winga commission credit — reuses payments journal/ledger only."""
from __future__ import annotations

from payments import journal, ledger
from payments.models import LedgerEntryKind, Transaction
from payments.money import Money


def post_winga_commission_credit(
    txn: Transaction,
    *,
    winga_principal: str,
    amount: Money,
    deal_ref: str,
):
    """Move reserved platform commission income into the Winga's wallet.

    Capture already credited house:commission-income. This posts the Winga share
    from that income account to the intermediary's user wallet (auditable).
    """
    cur = amount.currency
    return ledger.post_entry(
        txn,
        f"Winga commission {deal_ref}",
        [
            ledger.PostingSpec.debit(journal.commission_income(cur), amount),
            ledger.PostingSpec.credit(journal.user_wallet(winga_principal, cur), amount),
        ],
        kind=LedgerEntryKind.COMMISSION,
    )
