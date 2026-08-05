"""Assembles the default set of registered rails and the router from settings.

Live HTTP gateways are preferred when credentials are present. Simulated /
offline rails are only registered when TAIFA_ALLOW_STUB_ADAPTERS is true
(DEBUG/tests). Production without credentials simply omits that rail.
"""
from __future__ import annotations

from django.conf import settings

from .airtel import AirtelConfig, AirtelMoneyGateway
from .base import PaymentGateway
from .card_acquirer import CardAcquirerConfig, CardGateway
from .mpesa import MpesaConfig, MpesaGateway
from .registry import PaymentRouter
from .selcom import SelcomConfig, SelcomGateway
from .simulated import (
    AirtelMoneyGateway as SimulatedAirtelMoneyGateway,
    CardGateway as SimulatedCardGateway,
    OfflineMpesaGateway,
    SelcomGateway as SimulatedSelcomGateway,
)


def stubs_allowed() -> bool:
    return bool(getattr(settings, "TAIFA_ALLOW_STUB_ADAPTERS", True))


def mpesa_config() -> MpesaConfig:
    return MpesaConfig.from_settings(settings.MPESA)


def _mpesa_gateway() -> PaymentGateway | None:
    cfg = mpesa_config()
    if cfg.is_configured:
        return MpesaGateway(cfg)
    if stubs_allowed():
        return OfflineMpesaGateway()
    return None


def live_mpesa_gateway() -> MpesaGateway | None:
    """Return the real Daraja adapter when configured, else None."""
    gw = _mpesa_gateway()
    return gw if isinstance(gw, MpesaGateway) else None


def _airtel_gateway() -> PaymentGateway | None:
    cfg = AirtelConfig.from_settings()
    if cfg.is_configured:
        return AirtelMoneyGateway(cfg)
    if stubs_allowed():
        return SimulatedAirtelMoneyGateway()
    return None


def _selcom_gateway() -> PaymentGateway | None:
    cfg = SelcomConfig.from_settings()
    if cfg.is_configured:
        return SelcomGateway(cfg)
    if stubs_allowed():
        return SimulatedSelcomGateway()
    return None


def _card_gateway() -> PaymentGateway | None:
    cfg = CardAcquirerConfig.from_settings()
    if cfg.is_configured:
        return CardGateway(cfg)
    if stubs_allowed():
        return SimulatedCardGateway()
    return None


def default_gateways() -> list[PaymentGateway]:
    gateways: list[PaymentGateway] = []
    for factory in (_mpesa_gateway, _airtel_gateway, _selcom_gateway, _card_gateway):
        gw = factory()
        if gw is not None:
            gateways.append(gw)
    return gateways


def default_router() -> PaymentRouter:
    return PaymentRouter(default_gateways())
