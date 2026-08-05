"""End-to-end feature-phone SMS dispatch simulation (no DEBUG auto-accept)."""
from __future__ import annotations

from django.core.management import call_command
from django.core.management.base import BaseCommand

from mobility_channels.models import ChannelKind, DriverChannelBinding
from mobility_channels.services import handle_inbound_sms, sms_offer_body
from trips.models import DispatchOffer, DispatchOfferStatus, Driver, DriverAvailability, Trip, TripStatus
from trips.services import create_trip, dispatch_trip


class Command(BaseCommand):
    help = "Simulate feature-phone ride dispatch via SMS (register → offer → YES accept)"

    def add_arguments(self, parser):
        parser.add_argument(
            "--msisdn",
            default="+255712345604",
            help="Feature-phone driver MSISDN (default: Juma boda +255712345604)",
        )
        parser.add_argument(
            "--vehicle-mode",
            default="motorcycle",
            help="Vehicle mode for the trip (default: motorcycle)",
        )
        parser.add_argument(
            "--accept",
            action="store_true",
            help="Also simulate inbound SMS YES to accept the offer",
        )
        parser.add_argument(
            "--register",
            action="store_true",
            help="Register a fresh SMS driver instead of using seed binding",
        )
        parser.add_argument(
            "--passenger-phone",
            default="+255700111222",
            help="Passenger MSISDN stored on trip for accept notification",
        )

    def handle(self, *args, **options):
        call_command("seed_mobility", verbosity=0)
        call_command("seed_hybrid_dispatch", verbosity=0)

        msisdn: str = options["msisdn"]
        if options["register"]:
            reg = handle_inbound_sms(
                msisdn=msisdn,
                body="REGISTER SALIM MASAKI BODA",
            )
            self.stdout.write(self.style.WARNING(f"Register: {reg}"))
            if reg.get("status") != "registered":
                return

        binding = DriverChannelBinding.objects.select_related("driver").filter(msisdn=msisdn).first()
        if binding is None:
            self.stdout.write(self.style.ERROR(f"No DriverChannelBinding for {msisdn}. Run seed_hybrid_dispatch."))
            return

        driver = binding.driver
        Driver.objects.filter(pk=driver.pk).update(availability=DriverAvailability.AVAILABLE)
        # Reset other demo drivers stuck in offered state from prior app tests.
        Driver.objects.filter(owner_principal__startswith="demo-driver-").update(
            availability=DriverAvailability.AVAILABLE
        )

        self.stdout.write(self.style.SUCCESS(f"Feature-phone driver: {driver.full_name} ({msisdn})"))

        trip = create_trip(
            owner="sms-sim-passenger",
            pickup_name="Mwenge",
            pickup_lat=-6.75,
            pickup_lng=39.25,
            dropoff_name="Masaki",
            dropoff_lat=-6.74,
            dropoff_lng=39.28,
            vehicle_mode=options["vehicle_mode"],
            estimated_distance_meters=5000,
            estimated_duration_seconds=900,
            actor="simulate_sms_ride",
        )
        trip.metadata = {"passenger_msisdn": options["passenger_phone"]}
        trip.save(update_fields=["metadata", "updated_at"])

        offers = dispatch_trip(trip.id, actor="simulate_sms_ride")
        self.stdout.write(f"Trip {trip.id} · status={trip.status} · offers={len(offers)}")

        driver_offer = DispatchOffer.objects.filter(
            trip=trip,
            driver=driver,
            status=DispatchOfferStatus.PENDING,
        ).first()
        if driver_offer is None:
            self.stdout.write(
                self.style.WARNING(
                    "No pending offer for this driver — they may not rank for this vehicle_mode. "
                    "Try --register with motorcycle or use motorcycle seed driver Juma (+255712345604)."
                )
            )
            return

        body = sms_offer_body(trip=trip, offer=driver_offer, driver=driver)
        self.stdout.write("")
        self.stdout.write(self.style.HTTP_INFO("== OUTBOUND SMS (to driver) =="))
        self.stdout.write(body)
        self.stdout.write(self.style.HTTP_INFO("== Reply with: YES or 1 =="))
        self.stdout.write("")
        self.stdout.write("Webhook:")
        self.stdout.write(
            f'  curl -X POST http://127.0.0.1:8000/api/v1/mobility-channels/webhooks/sms/inbound '
            f'-H "Content-Type: application/json" '
            f'-d "{{\\"from\\": \\"{msisdn}\\", \\"text\\": \\"YES\\"}}"'
        )

        if options["accept"]:
            result = handle_inbound_sms(msisdn=msisdn, body="YES")
            self.stdout.write("")
            self.stdout.write(self.style.SUCCESS(f"Inbound YES -> {result}"))
            trip.refresh_from_db()
            self.stdout.write(f"Trip status: {trip.status} · driver: {trip.driver_name}")
            if trip.status in {TripStatus.DRIVER_ASSIGNED, TripStatus.DRIVER_EN_ROUTE}:
                self.stdout.write(self.style.SUCCESS("Passenger would receive SMS with driver contact + trip PIN."))
