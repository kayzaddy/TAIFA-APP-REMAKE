from django.db import migrations, models
import django.db.models.deletion
import uuid


class Migration(migrations.Migration):

    dependencies = [
        ("trips", "0016_transit_rbac"),
    ]

    operations = [
        migrations.CreateModel(
            name="TransitScheduledRun",
            fields=[
                (
                    "id",
                    models.UUIDField(
                        default=uuid.uuid4, editable=False, primary_key=True, serialize=False
                    ),
                ),
                ("driver_owner", models.CharField(db_index=True, max_length=128)),
                ("vehicle_label", models.CharField(blank=True, default="", max_length=64)),
                ("scheduled_at", models.DateTimeField(db_index=True)),
                ("origin_stop", models.CharField(blank=True, default="", max_length=64)),
                ("destination_stop", models.CharField(blank=True, default="", max_length=64)),
                (
                    "status",
                    models.CharField(
                        choices=[
                            ("scheduled", "Scheduled"),
                            ("boarding", "Boarding"),
                            ("departed", "Departed"),
                            ("completed", "Completed"),
                            ("cancelled", "Cancelled"),
                        ],
                        db_index=True,
                        default="scheduled",
                        max_length=16,
                    ),
                ),
                ("metadata", models.JSONField(blank=True, default=dict)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                (
                    "route",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="scheduled_runs",
                        to="trips.publictransitroute",
                    ),
                ),
            ],
            options={
                "ordering": ["scheduled_at"],
                "indexes": [
                    models.Index(
                        fields=["driver_owner", "scheduled_at", "status"],
                        name="trips_trans_driver__a8f2c1_idx",
                    )
                ],
            },
        ),
    ]
