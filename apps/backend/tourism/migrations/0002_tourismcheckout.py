# Generated manually for TAIFA-TOUR-003/004

import uuid

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ("taifa_tourism", "0001_initial"),
    ]

    operations = [
        migrations.CreateModel(
            name="TourismCheckout",
            fields=[
                (
                    "id",
                    models.UUIDField(
                        default=uuid.uuid4,
                        editable=False,
                        primary_key=True,
                        serialize=False,
                    ),
                ),
                ("owner", models.CharField(db_index=True, max_length=128)),
                (
                    "status",
                    models.CharField(
                        choices=[
                            ("draft", "Draft"),
                            ("ready", "Ready to pay"),
                            ("paid", "Paid"),
                        ],
                        default="ready",
                        max_length=16,
                    ),
                ),
                ("include_insurance", models.BooleanField(default=False)),
                (
                    "insurance_plan_id",
                    models.CharField(blank=True, default="", max_length=64),
                ),
                (
                    "insurance_plan_name",
                    models.CharField(blank=True, default="", max_length=128),
                ),
                (
                    "insurance_provider",
                    models.CharField(blank=True, default="", max_length=128),
                ),
                ("insurance_premium_minor", models.BigIntegerField(default=0)),
                ("insurance_coverage_minor", models.BigIntegerField(default=0)),
                ("insurance_policy_id", models.UUIDField(blank=True, null=True)),
                ("travel_subtotal_minor", models.BigIntegerField(default=0)),
                ("protection_subtotal_minor", models.BigIntegerField(default=0)),
                ("total_minor", models.BigIntegerField(default=0)),
                ("currency", models.CharField(default="TZS", max_length=8)),
                ("lines", models.JSONField(blank=True, default=list)),
                (
                    "payment_ref",
                    models.CharField(blank=True, default="", max_length=64),
                ),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                (
                    "trip",
                    models.OneToOneField(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="checkout",
                        to="taifa_tourism.tourismtrip",
                    ),
                ),
            ],
            options={
                "ordering": ["-updated_at"],
            },
        ),
    ]
