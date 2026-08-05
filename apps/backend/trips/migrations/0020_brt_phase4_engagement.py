from django.db import migrations, models
import django.db.models.deletion
import uuid


class Migration(migrations.Migration):

    dependencies = [
        ("trips", "0019_brt_phase3_avl"),
    ]

    operations = [
        migrations.CreateModel(
            name="TransitPassengerProfile",
            fields=[
                (
                    "id",
                    models.UUIDField(
                        default=uuid.uuid4, editable=False, primary_key=True, serialize=False
                    ),
                ),
                ("owner", models.CharField(db_index=True, max_length=128, unique=True)),
                ("home_stop", models.CharField(blank=True, default="", max_length=64)),
                ("work_stop", models.CharField(blank=True, default="", max_length=64)),
                ("preferred_language", models.CharField(default="sw", max_length=8)),
                ("accessibility", models.JSONField(blank=True, default=dict)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
            ],
        ),
        migrations.CreateModel(
            name="TransitFavorite",
            fields=[
                (
                    "id",
                    models.UUIDField(
                        default=uuid.uuid4, editable=False, primary_key=True, serialize=False
                    ),
                ),
                ("owner", models.CharField(db_index=True, max_length=128)),
                (
                    "subject_type",
                    models.CharField(
                        choices=[("station", "Station"), ("route", "Route")], max_length=16
                    ),
                ),
                ("subject_code", models.CharField(db_index=True, max_length=64)),
                ("label", models.CharField(blank=True, default="", max_length=128)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
            ],
            options={
                "constraints": [
                    models.UniqueConstraint(
                        fields=("owner", "subject_type", "subject_code"),
                        name="trips_unique_transit_favorite",
                    )
                ],
            },
        ),
        migrations.CreateModel(
            name="TransitNotification",
            fields=[
                (
                    "id",
                    models.UUIDField(
                        default=uuid.uuid4, editable=False, primary_key=True, serialize=False
                    ),
                ),
                ("owner", models.CharField(db_index=True, max_length=128)),
                ("event_type", models.CharField(db_index=True, max_length=64)),
                ("title", models.CharField(max_length=255)),
                ("body", models.TextField(blank=True, default="")),
                ("payload", models.JSONField(blank=True, default=dict)),
                ("read", models.BooleanField(db_index=True, default=False)),
                ("deduplication_key", models.CharField(max_length=160, unique=True)),
                ("created_at", models.DateTimeField(auto_now_add=True, db_index=True)),
            ],
        ),
        migrations.CreateModel(
            name="TransitFeedback",
            fields=[
                (
                    "id",
                    models.UUIDField(
                        default=uuid.uuid4, editable=False, primary_key=True, serialize=False
                    ),
                ),
                ("owner", models.CharField(db_index=True, max_length=128)),
                ("rating", models.PositiveSmallIntegerField()),
                ("comment", models.TextField(blank=True, default="")),
                ("tags", models.JSONField(blank=True, default=list)),
                ("sentiment", models.CharField(default="neutral", max_length=16)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                (
                    "route",
                    models.ForeignKey(
                        blank=True,
                        null=True,
                        on_delete=django.db.models.deletion.SET_NULL,
                        related_name="feedback",
                        to="trips.publictransitroute",
                    ),
                ),
                (
                    "ticket",
                    models.ForeignKey(
                        blank=True,
                        null=True,
                        on_delete=django.db.models.deletion.SET_NULL,
                        related_name="feedback",
                        to="trips.transportticket",
                    ),
                ),
            ],
            options={"ordering": ["-created_at"]},
        ),
    ]
