from django.db import migrations, models
import django.db.models.deletion
import uuid


class Migration(migrations.Migration):

    dependencies = [
        ("trips", "0018_transit_driver_rbac"),
    ]

    operations = [
        migrations.CreateModel(
            name="TransitAvlVehicle",
            fields=[
                (
                    "id",
                    models.UUIDField(
                        default=uuid.uuid4, editable=False, primary_key=True, serialize=False
                    ),
                ),
                ("vehicle_label", models.CharField(db_index=True, max_length=64, unique=True)),
                ("latitude", models.DecimalField(decimal_places=6, max_digits=9)),
                ("longitude", models.DecimalField(decimal_places=6, max_digits=9)),
                ("heading", models.SmallIntegerField(default=0)),
                ("speed_kmh", models.PositiveSmallIntegerField(default=0)),
                ("progress_e4", models.PositiveIntegerField(default=0)),
                ("next_stop_code", models.CharField(blank=True, default="", max_length=64)),
                ("eta_next_stop_seconds", models.PositiveIntegerField(default=0)),
                (
                    "status",
                    models.CharField(
                        choices=[
                            ("in_service", "In Service"),
                            ("at_station", "At Station"),
                            ("offline", "Offline"),
                        ],
                        db_index=True,
                        default="in_service",
                        max_length=16,
                    ),
                ),
                ("active", models.BooleanField(db_index=True, default=True)),
                ("recorded_at", models.DateTimeField(auto_now=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                (
                    "route",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="avl_vehicles",
                        to="trips.publictransitroute",
                    ),
                ),
                (
                    "scheduled_run",
                    models.ForeignKey(
                        blank=True,
                        null=True,
                        on_delete=django.db.models.deletion.SET_NULL,
                        related_name="avl_snapshots",
                        to="trips.transitscheduledrun",
                    ),
                ),
            ],
            options={
                "ordering": ["vehicle_label"],
                "indexes": [
                    models.Index(
                        fields=["route", "active", "status"],
                        name="trips_trans_route_i_6f4a21_idx",
                    )
                ],
            },
        ),
    ]
