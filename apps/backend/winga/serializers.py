"""Winga REST serializers."""
from __future__ import annotations

from rest_framework import serializers

from .models import (
    BrokerageDeal,
    BrokerageDomain,
    Category,
    CommissionEvent,
    CommissionRule,
    Favorite,
    Lead,
    Offering,
    ProviderProfile,
    Quotation,
    Review,
    WingaProfile,
)


class BrokerageDomainSerializer(serializers.ModelSerializer):
    class Meta:
        model = BrokerageDomain
        fields = (
            "id",
            "code",
            "name",
            "description",
            "active",
            "default_commission_bps",
            "workflow_definition_code",
            "attributes_schema",
        )


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ("id", "domain", "parent", "code", "name", "active")


class WingaProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = WingaProfile
        fields = (
            "id",
            "principal",
            "kind",
            "display_name",
            "bio",
            "verification_status",
            "certification",
            "reputation_score_e4",
            "active",
            "created_at",
        )
        read_only_fields = ("verification_status", "reputation_score_e4", "created_at")


class ProviderProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProviderProfile
        fields = (
            "id",
            "principal",
            "legal_name",
            "trading_name",
            "verification_status",
            "locations",
            "operating_hours",
            "reputation_score_e4",
            "active",
            "merchant",
            "created_at",
        )
        read_only_fields = ("verification_status", "reputation_score_e4", "merchant", "created_at")


class OfferingSerializer(serializers.ModelSerializer):
    class Meta:
        model = Offering
        fields = (
            "id",
            "provider",
            "domain",
            "category",
            "kind",
            "title",
            "description",
            "currency",
            "price_minor",
            "compare_at_minor",
            "inventory_qty",
            "attributes",
            "variants",
            "availability",
            "locations",
            "active",
            "created_at",
        )


class LeadSerializer(serializers.ModelSerializer):
    class Meta:
        model = Lead
        fields = (
            "id",
            "winga",
            "customer_principal",
            "domain",
            "offering",
            "title",
            "notes",
            "pipeline_stage",
            "priority_e4",
            "follow_up_at",
            "created_at",
        )


class QuotationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Quotation
        fields = (
            "id",
            "lead",
            "provider",
            "currency",
            "amount_minor",
            "line_items",
            "valid_until",
            "status",
            "notes",
            "created_at",
        )


class BrokerageDealSerializer(serializers.ModelSerializer):
    class Meta:
        model = BrokerageDeal
        fields = (
            "id",
            "reference",
            "domain",
            "winga",
            "provider",
            "customer_principal",
            "offering",
            "lead",
            "quotation",
            "stage",
            "currency",
            "amount_minor",
            "payment_ref",
            "booking",
            "fulfillment",
            "metadata",
            "created_at",
            "updated_at",
            "closed_at",
        )
        read_only_fields = ("reference", "payment_ref", "stage", "created_at", "updated_at", "closed_at")


class CommissionRuleSerializer(serializers.ModelSerializer):
    class Meta:
        model = CommissionRule
        fields = (
            "id",
            "code",
            "name",
            "kind",
            "domain",
            "category",
            "provider",
            "winga",
            "bps",
            "flat_minor",
            "tiers",
            "multi_level",
            "campaign_code",
            "priority",
            "active",
        )


class CommissionEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = CommissionEvent
        fields = (
            "id",
            "deal",
            "rule",
            "winga",
            "kind",
            "currency",
            "basis_amount_minor",
            "commission_minor",
            "bps_applied",
            "level",
            "status",
            "ledger_txn_id",
            "calculation",
            "created_at",
            "settled_at",
        )
        read_only_fields = fields


class ReviewSerializer(serializers.ModelSerializer):
    class Meta:
        model = Review
        fields = (
            "id",
            "deal",
            "author_principal",
            "subject_type",
            "subject_id",
            "rating_e4",
            "comment",
            "created_at",
        )
        read_only_fields = ("author_principal", "created_at")


class FavoriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Favorite
        fields = ("id", "owner_principal", "offering", "created_at")
        read_only_fields = ("owner_principal", "created_at")
