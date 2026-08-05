"""Risk Engine — decisions before money moves.

Does not post journals. Does not know ledger SQL. Returns allow | deny | review.
Automated money APIs treat `review` as deny until an ops approval path exists.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from datetime import timedelta

from django.conf import settings
from django.db.models import Sum
from django.utils import timezone

from .models import Transaction, TransactionDirection, TransactionStatus
from .money import Money


class RiskDecisionKind:
    ALLOW = "allow"
    DENY = "deny"
    REVIEW = "review"


@dataclass(frozen=True)
class RiskDecision:
    kind: str
    code: str = ""
    message: str = ""
    rules_fired: tuple[str, ...] = field(default_factory=tuple)

    @property
    def allowed(self) -> bool:
        return self.kind == RiskDecisionKind.ALLOW


class RiskDenied(Exception):
    def __init__(self, decision: RiskDecision):
        self.decision = decision
        super().__init__(decision.message or decision.code)


@dataclass
class RiskContext:
    owner: str
    amount: Money
    operation: str  # transfer | withdrawal | refund | topup
    device_id: str = ""
    ip: str | None = None
    msisdn: str = ""
    counterparty: str = ""


class RiskEngine:
    """Configurable velocity, limits, and sanctions checks."""

    def evaluate(self, ctx: RiskContext) -> RiskDecision:
        decision = self._evaluate(ctx)
        try:
            from .metrics import observe_risk_decision

            observe_risk_decision(str(decision.kind))
        except Exception:
            pass
        return decision

    def _evaluate(self, ctx: RiskContext) -> RiskDecision:
        fired: list[str] = []

        sanctions = set(getattr(settings, "RISK_SANCTIONS_OWNERS", []) or [])
        if ctx.owner in sanctions:
            return RiskDecision(
                RiskDecisionKind.DENY,
                code="SANCTIONS_HIT",
                message="Principal is on the sanctions / watch list.",
                rules_fired=("sanctions",),
            )

        per_txn = int(getattr(settings, "RISK_PER_TXN_LIMIT_MINOR", 0) or 0)
        if per_txn > 0 and ctx.amount.minor_units > per_txn:
            return RiskDecision(
                RiskDecisionKind.DENY,
                code="PER_TXN_LIMIT",
                message=f"Amount exceeds per-transaction limit ({per_txn} minor units).",
                rules_fired=("per_txn_limit",),
            )

        review_above = int(getattr(settings, "RISK_REVIEW_ABOVE_MINOR", 0) or 0)
        if review_above > 0 and ctx.amount.minor_units > review_above:
            return RiskDecision(
                RiskDecisionKind.REVIEW,
                code="MANUAL_REVIEW_REQUIRED",
                message="Amount requires manual review before posting.",
                rules_fired=("review_threshold",),
            )

        daily = int(getattr(settings, "RISK_DAILY_DEBIT_LIMIT_MINOR", 0) or 0)
        if daily > 0 and ctx.operation in {"transfer", "withdrawal"}:
            since = timezone.now() - timedelta(hours=24)
            spent = (
                Transaction.objects.filter(
                    owner=ctx.owner,
                    direction=TransactionDirection.DEBIT,
                    status__in=[
                        TransactionStatus.SUCCEEDED,
                        TransactionStatus.PROCESSING,
                        TransactionStatus.APPROVED,
                        TransactionStatus.PENDING,
                    ],
                    created_at__gte=since,
                    currency=ctx.amount.currency.code,
                ).aggregate(s=Sum("amount_minor"))["s"]
                or 0
            )
            if spent + ctx.amount.minor_units > daily:
                return RiskDecision(
                    RiskDecisionKind.DENY,
                    code="DAILY_DEBIT_LIMIT",
                    message="Daily debit limit would be exceeded.",
                    rules_fired=("daily_debit_limit",),
                )
            fired.append("daily_debit_limit_ok")

        daily_credit = int(getattr(settings, "RISK_DAILY_CREDIT_LIMIT_MINOR", 0) or 0)
        if daily_credit > 0 and ctx.operation in {"topup"}:
            since = timezone.now() - timedelta(hours=24)
            credited = (
                Transaction.objects.filter(
                    owner=ctx.owner,
                    direction=TransactionDirection.CREDIT,
                    status__in=[
                        TransactionStatus.SUCCEEDED,
                        TransactionStatus.PROCESSING,
                        TransactionStatus.PENDING,
                    ],
                    created_at__gte=since,
                    currency=ctx.amount.currency.code,
                ).aggregate(s=Sum("amount_minor"))["s"]
                or 0
            )
            if credited + ctx.amount.minor_units > daily_credit:
                return RiskDecision(
                    RiskDecisionKind.DENY,
                    code="DAILY_CREDIT_LIMIT",
                    message="Daily credit limit would be exceeded.",
                    rules_fired=("daily_credit_limit",),
                )
            fired.append("daily_credit_limit_ok")

        window = int(getattr(settings, "RISK_VELOCITY_WINDOW_SECONDS", 60) or 60)
        max_n = int(getattr(settings, "RISK_VELOCITY_MAX_TXNS", 30) or 30)
        if max_n > 0:
            since = timezone.now() - timedelta(seconds=window)
            count = Transaction.objects.filter(owner=ctx.owner, created_at__gte=since).count()
            if count >= max_n:
                return RiskDecision(
                    RiskDecisionKind.DENY,
                    code="VELOCITY_EXCEEDED",
                    message=f"More than {max_n} transactions in {window}s.",
                    rules_fired=("velocity",),
                )
            fired.append("velocity_ok")

        return RiskDecision(
            RiskDecisionKind.ALLOW,
            code="OK",
            rules_fired=tuple(fired) or ("default_allow",),
        )


def default_risk_engine() -> RiskEngine:
    return RiskEngine()
