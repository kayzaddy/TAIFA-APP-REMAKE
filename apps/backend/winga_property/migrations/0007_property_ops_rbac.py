from django.db import migrations


PROPERTY_OPS_ROLES = {
    "property-ops-viewer": [
        "winga.property.ops.read",
    ],
    "property-ops-officer": [
        "winga.property.ops.read",
        "winga.property.ops.write",
    ],
}


def seed_property_ops_roles(apps, schema_editor):
    PlatformRole = apps.get_model("enterprise", "PlatformRole")
    for code, permissions in PROPERTY_OPS_ROLES.items():
        role, _ = PlatformRole.objects.get_or_create(
            code=code,
            defaults={"name": code.replace("-", " ").title()},
        )
        role.permissions = permissions
        role.save(update_fields=["permissions"])


class Migration(migrations.Migration):

    dependencies = [
        ("enterprise", "0001_phase3_financial_platform"),
        ("winga_property", "0006_phase6_ops"),
    ]

    operations = [
        migrations.RunPython(seed_property_ops_roles, migrations.RunPython.noop),
    ]
