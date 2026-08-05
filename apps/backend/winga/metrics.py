"""Winga observability metrics."""
from __future__ import annotations

from prometheus_client import Counter

LEADS = Counter("taifa_winga_leads_total", "Winga leads created", ["domain"])
DEALS = Counter("taifa_winga_deals_total", "Winga deals opened", ["domain"])
DEAL_STAGES = Counter("taifa_winga_deal_stages_total", "Deal stage transitions", ["domain", "stage"])
DEALS_PAID = Counter("taifa_winga_deals_paid_total", "Deals paid via Taifa Payments", ["domain"])
COMMISSIONS = Counter("taifa_winga_commissions_settled_total", "Commission payouts settled", ["domain"])


def observe_lead_created(*, domain: str) -> None:
    LEADS.labels(domain=domain).inc()


def observe_deal_opened(*, domain: str) -> None:
    DEALS.labels(domain=domain).inc()


def observe_deal_stage(*, domain: str, stage: str) -> None:
    DEAL_STAGES.labels(domain=domain, stage=stage).inc()


def observe_deal_paid(*, domain: str) -> None:
    DEALS_PAID.labels(domain=domain).inc()


def observe_commission_settled(*, domain: str) -> None:
    COMMISSIONS.labels(domain=domain).inc()
