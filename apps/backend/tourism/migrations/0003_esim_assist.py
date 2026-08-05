# TAIFA-TOUR-007/009

import uuid

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ("taifa_tourism", "0002_tourismcheckout"),
    ]

    operations = [
        migrations.AddField(
            model_name="tourismcheckout",
            name="connectivity_subtotal_minor",
            field=models.BigIntegerField(default=0),
        ),
        migrations.AddField(
            model_name="tourismcheckout",
            name="esim_order_id",
            field=models.UUIDField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name="tourismcheckout",
            name="esim_plan_id",
            field=models.CharField(blank=True, default="", max_length=64),
        ),
        migrations.AddField(
            model_name="tourismcheckout",
            name="esim_plan_name",
            field=models.CharField(blank=True, default="", max_length=128),
        ),
        migrations.AddField(
            model_name="tourismcheckout",
            name="esim_price_minor",
            field=models.BigIntegerField(default=0),
        ),
        migrations.AddField(
            model_name="tourismcheckout",
            name="include_esim",
            field=models.BooleanField(default=False),
        ),
        migrations.CreateModel(
            name="TourismEsimOrder",
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
                ("plan_id", models.CharField(max_length=64)),
                ("plan_name", models.CharField(max_length=128)),
                ("data_gb", models.PositiveSmallIntegerField(default=5)),
                ("days", models.PositiveSmallIntegerField(default=7)),
                ("price_minor", models.BigIntegerField()),
                ("currency", models.CharField(default="TZS", max_length=8)),
                (
                    "status",
                    models.CharField(
                        choices=[
                            ("pending", "Pending"),
                            ("provisioned", "Provisioned"),
                            ("active", "Active"),
                        ],
                        default="provisioned",
                        max_length=16,
                    ),
                ),
                ("activation_code", models.CharField(blank=True, default="", max_length=64)),
                ("qr_payload", models.TextField(blank=True, default="")),
                ("payment_ref", models.CharField(blank=True, default="", max_length=64)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                (
                    "trip",
                    models.ForeignKey(
                        blank=True,
                        null=True,
                        on_delete=django.db.models.deletion.SET_NULL,
                        related_name="esim_orders",
                        to="taifa_tourism.tourismtrip",
                    ),
                ),
            ],
            options={"ordering": ["-created_at"]},
        ),
        migrations.CreateModel(
            name="TourismAssistanceCase",
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
                ("kind", models.CharField(default="sos", max_length=16)),
                (
                    "status",
                    models.CharField(
                        choices=[
                            ("open", "Open"),
                            ("acknowledged", "Acknowledged"),
                            ("resolved", "Resolved"),
                        ],
                        default="open",
                        max_length=16,
                    ),
                ),
                (
                    "latitude",
                    models.DecimalField(
                        blank=True, decimal_places=6, max_digits=9, null=True
                    ),
                ),
                (
                    "longitude",
                    models.DecimalField(
                        blank=True, decimal_places=6, max_digits=9, null=True
                    ),
                ),
                ("notes", models.CharField(blank=True, default="", max_length=500)),
                ("safety_incident_id", models.UUIDField(blank=True, null=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                (
                    "trip",
                    models.ForeignKey(
                        blank=True,
                        null=True,
                        on_delete=django.db.models.deletion.SET_NULL,
                        related_name="assistance_cases",
                        to="taifa_tourism.tourismtrip",
                    ),
                ),
            ],
            options={"ordering": ["-created_at"]},
        ),
    ]
