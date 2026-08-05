from django.core.management.base import BaseCommand

from enterprise.models import Merchant, MerchantStatus

from acceptance import services


class Command(BaseCommand):
    help = "Seed MAP acceptance profile, static QR, sample link & invoice"

    def handle(self, *args, **options):
        merchant, _ = Merchant.objects.get_or_create(
            code="map-seed-retail",
            defaults={
                "legal_name": "MAP Seed Retail Ltd",
                "trading_name": "MAP Seed Shop",
                "status": MerchantStatus.ACTIVE,
                "sector": "retail",
                "fee_bps": 0,
                "tax_bps": 0,
                "commission_bps": 0,
            },
        )
        if merchant.status != MerchantStatus.ACTIVE:
            merchant.status = MerchantStatus.ACTIVE
            merchant.save(update_fields=["status", "updated_at"])
        profile = services.ensure_profile(merchant=merchant)
        qr, _ = services.issue_qr(merchant=merchant, kind="static")
        dyn, intent = services.issue_qr(
            merchant=merchant, kind="dynamic", amount_minor=2500, description="Seed snack"
        )
        link = services.create_payment_link(
            merchant=merchant, amount_minor=5000, purpose="order", description="Seed link"
        )
        inv, inv_intent, inv_qr = services.create_invoice(
            merchant=merchant,
            invoice_number="SEED-INV-1",
            amount_minor=10_000,
            customer_name="Seed Customer",
            line_items=[{"desc": "Seed service", "amount_minor": 10000}],
        )
        term = services.register_terminal(
            merchant=merchant, code="POS-1", kind="pos", softpos_ready=True, nfc_ready=False
        )
        self.stdout.write(
            self.style.SUCCESS(
                f"MAP seeded merchant={merchant.id} profile={profile.qr_identity} "
                f"static_qr={qr.public_code} dynamic={dyn.public_code} "
                f"link={link.path_token} invoice={inv.public_code} terminal={term.code}"
            )
        )
