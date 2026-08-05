"""Verify Daraja OAuth credentials without initiating an STK push."""
from __future__ import annotations

from django.core.management.base import BaseCommand, CommandError

from payments.gateways.factory import live_mpesa_gateway, mpesa_config


class Command(BaseCommand):
    help = "Ping Daraja OAuth with configured MPESA_* credentials (sandbox or production)."

    def handle(self, *args, **options):
        cfg = mpesa_config()
        if not cfg.is_configured:
            raise CommandError(
                "Daraja is not configured. Set MPESA_CONSUMER_KEY and "
                "MPESA_CONSUMER_SECRET in apps/backend/.env (sandbox passkey "
                "defaults when MPESA_ENVIRONMENT=sandbox)."
            )

        gateway = live_mpesa_gateway()
        if gateway is None:
            raise CommandError("Factory did not return a live MpesaGateway.")

        try:
            token = gateway._access_token()
        except Exception as exc:  # noqa: BLE001 — surface Daraja/network errors
            raise CommandError(f"OAuth failed against {cfg.base_url}: {exc}") from exc

        masked = f"{token[:8]}…{token[-4:]}" if len(token) > 16 else "(token)"
        self.stdout.write(self.style.SUCCESS(
            f"Daraja OAuth OK · env={cfg.environment} · host={cfg.base_url} · "
            f"shortcode={cfg.shortcode} · token={masked}"
        ))
        if "example.com" in (cfg.callback_base_url or ""):
            self.stdout.write(self.style.WARNING(
                "MPESA_CALLBACK_BASE_URL is not public — after PIN, settle via "
                "POST /payments/topups/{id}/poll-status (or set an ngrok HTTPS URL)."
            ))
