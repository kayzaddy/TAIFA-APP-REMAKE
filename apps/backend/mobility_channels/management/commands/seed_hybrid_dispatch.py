from django.core.management.base import BaseCommand

from mobility_channels.models import DeviceCapability, DriverChannelBinding
from mobility_channels.services import ensure_binding
from trips.models import Driver


class Command(BaseCommand):
    help = "Seed hybrid dispatch channel bindings for demo drivers"

    def handle(self, *args, **options):
        created = 0
        drivers = list(Driver.objects.filter(status="active")[:6])
        samples = [
            ("+255712345601", DeviceCapability.SMARTPHONE, True, True),
            ("+255712345602", DeviceCapability.FEATURE_PHONE, False, False),
            ("+255712345603", DeviceCapability.FEATURE_PHONE, False, False),
            ("+255712345604", DeviceCapability.FEATURE_PHONE, False, False),
        ]
        for driver, (msisdn, cap, net, gps) in zip(drivers, samples):
            _, was_new = DriverChannelBinding.objects.get_or_create(driver=driver)
            ensure_binding(
                driver=driver,
                msisdn=msisdn,
                device_capability=cap,
                has_internet=net,
                has_gps=gps,
            )
            if was_new:
                created += 1
        self.stdout.write(
            self.style.SUCCESS(
                f"Hybrid dispatch bindings ensured for {len(samples)} drivers ({created} new)"
            )
        )
