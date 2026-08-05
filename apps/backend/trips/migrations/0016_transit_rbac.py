from django.db import migrations


TRANSIT_ROLES = {
    "transit-validator": ["mobility.transit.validate"],
}


def seed_transit_roles(apps, schema_editor):
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
        ("trips", "0015_brt_phase1"),
    ]

    operations = [
        migrations.RunPython(seed_transit_roles, migrations.RunPython.noop),
    ]
