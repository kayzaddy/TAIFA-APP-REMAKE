from django.db import migrations


TRANSIT_ROLES = {
    "transit-driver": ["mobility.transit.driver"],
}


def seed_transit_driver_role(apps, schema_editor):
    PlatformRole = apps.get_model("enterprise", "PlatformRole")
    for code, permissions in TRANSIT_ROLES.items():
        role, _ = PlatformRole.objects.get_or_create(
            code=code,
            defaults={"name": code.replace("-", " ").title()},
        )
        role.permissions = permissions
        role.save(update_fields=["permissions"])


class Migration(migrations.Migration):

    dependencies = [
        ("enterprise", "0001_phase3_financial_platform"),
        ("trips", "0017_brt_phase2_scheduled_runs"),
    ]

    operations = [
        migrations.RunPython(seed_transit_driver_role, migrations.RunPython.noop),
    ]
