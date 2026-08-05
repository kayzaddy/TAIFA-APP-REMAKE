from rest_framework import serializers

from .models import (
    PropertyCategory,
    PropertyFavorite,
    PropertyListing,
    PropertyLiveMessage,
    PropertyLiveSession,
    PropertyMedia,
    PropertyOwner,
    PropertySharedDocument,
    PropertyTimelineEvent,
    PropertyType,
    PropertyVerificationEvent,
    PropertyViewingAppointment,
    PropertyViewingPass,
    PropertyWingaAssignment,
    SavedSearch,
)


class PropertyCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = PropertyCategory
        fields = ["id", "code", "name", "description", "icon", "sort_order"]


class PropertyTypeSerializer(serializers.ModelSerializer):
    category_code = serializers.CharField(source="category.code", read_only=True)

    class Meta:
        model = PropertyType
        fields = ["id", "category_code", "code", "name", "description"]


class PropertyOwnerSerializer(serializers.ModelSerializer):
    class Meta:
        model = PropertyOwner
        fields = [
            "id",
            "principal",
            "display_name",
            "phone",
            "email",
            "role",
            "verification_status",
            "bio",
            "active",
            "created_at",
        ]
        read_only_fields = ["id", "principal", "verification_status", "created_at"]


class PropertyMediaSerializer(serializers.ModelSerializer):
    class Meta:
        model = PropertyMedia
        fields = [
            "id",
            "kind",
            "url",
            "caption",
            "sort_order",
            "is_primary",
            "duration_seconds",
            "room_code",
            "tour_kind",
            "is_hd",
            "panorama_url",
            "floor_plan_data",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]


class PropertyListingSerializer(serializers.ModelSerializer):
    category_code = serializers.CharField(source="category.code", read_only=True)
    property_type_code = serializers.CharField(source="property_type.code", read_only=True)
    owner_name = serializers.CharField(source="owner.display_name", read_only=True)
    owner_phone = serializers.SerializerMethodField()
    owner_email = serializers.SerializerMethodField()
    media = PropertyMediaSerializer(many=True, read_only=True)
    primary_photo_url = serializers.SerializerMethodField()
    is_unlocked = serializers.SerializerMethodField()

    class Meta:
        model = PropertyListing
        fields = [
            "id",
            "owner_name",
            "owner_phone",
            "owner_email",
            "category_code",
            "property_type_code",
            "transaction_type",
            "title",
            "description",
            "currency",
            "price_minor",
            "deposit_minor",
            "beds",
            "baths",
            "area_sqm",
            "address_line",
            "ward",
            "district",
            "region",
            "latitude",
            "longitude",
            "verification_status",
            "verified_at",
            "active",
            "published_at",
            "attributes",
            "media",
            "primary_photo_url",
            "is_unlocked",
            "created_at",
            "updated_at",
        ]

    def get_primary_photo_url(self, obj: PropertyListing) -> str:
        primary = obj.media.filter(is_primary=True).first()
        if primary:
            return primary.url
        first = obj.media.filter(kind="photo").first()
        return first.url if first else ""

    def get_is_unlocked(self, obj: PropertyListing) -> bool:
        return bool(self.context.get("unlocked", False))

    def get_owner_phone(self, obj: PropertyListing) -> str:
        if self.context.get("unlocked"):
            return obj.owner.phone
        return ""

    def get_owner_email(self, obj: PropertyListing) -> str:
        if self.context.get("unlocked"):
            return obj.owner.email
        return ""

    def to_representation(self, obj: PropertyListing):
        data = super().to_representation(obj)
        if not self.context.get("unlocked"):
            data["address_line"] = ""
            if obj.latitude and obj.longitude:
                data["latitude"] = float(obj.latitude) // 1 * 1 + 0.01
                data["longitude"] = float(obj.longitude) // 1 * 1 + 0.01
        return data


class PropertyListingCreateSerializer(serializers.Serializer):
    category_code = serializers.CharField()
    property_type_code = serializers.CharField()
    transaction_type = serializers.CharField(default="rent")
    title = serializers.CharField(max_length=255)
    description = serializers.CharField(required=False, allow_blank=True, default="")
    currency = serializers.CharField(default="TZS")
    price_minor = serializers.IntegerField(min_value=0)
    deposit_minor = serializers.IntegerField(min_value=0, default=0)
    beds = serializers.IntegerField(min_value=0, default=0)
    baths = serializers.IntegerField(min_value=0, default=0)
    area_sqm = serializers.IntegerField(min_value=0, default=0)
    address_line = serializers.CharField(required=False, allow_blank=True, default="")
    ward = serializers.CharField(required=False, allow_blank=True, default="")
    district = serializers.CharField(required=False, allow_blank=True, default="")
    region = serializers.CharField(required=False, allow_blank=True, default="")
    latitude = serializers.DecimalField(max_digits=10, decimal_places=7, default=0)
    longitude = serializers.DecimalField(max_digits=10, decimal_places=7, default=0)
    attributes = serializers.DictField(required=False, default=dict)


class PropertyListingPatchSerializer(serializers.Serializer):
    title = serializers.CharField(required=False)
    description = serializers.CharField(required=False, allow_blank=True)
    price_minor = serializers.IntegerField(required=False, min_value=0)
    deposit_minor = serializers.IntegerField(required=False, min_value=0)
    beds = serializers.IntegerField(required=False, min_value=0)
    baths = serializers.IntegerField(required=False, min_value=0)
    area_sqm = serializers.IntegerField(required=False, min_value=0)
    address_line = serializers.CharField(required=False, allow_blank=True)
    ward = serializers.CharField(required=False, allow_blank=True)
    district = serializers.CharField(required=False, allow_blank=True)
    region = serializers.CharField(required=False, allow_blank=True)
    latitude = serializers.DecimalField(required=False, max_digits=10, decimal_places=7)
    longitude = serializers.DecimalField(required=False, max_digits=10, decimal_places=7)
    active = serializers.BooleanField(required=False)
    attributes = serializers.DictField(required=False)


class PropertyMediaCreateSerializer(serializers.Serializer):
    kind = serializers.ChoiceField(choices=["photo", "video"])
    url = serializers.URLField()
    caption = serializers.CharField(required=False, allow_blank=True, default="")
    sort_order = serializers.IntegerField(min_value=0, default=0)
    is_primary = serializers.BooleanField(default=False)
    duration_seconds = serializers.IntegerField(required=False, allow_null=True)
    room_code = serializers.CharField(required=False, allow_blank=True, default="")
    tour_kind = serializers.CharField(required=False, allow_blank=True, default="gallery")
    is_hd = serializers.BooleanField(required=False, default=False)
    panorama_url = serializers.URLField(required=False, allow_blank=True, default="")
    floor_plan_data = serializers.DictField(required=False, default=dict)


class PropertyFavoriteSerializer(serializers.ModelSerializer):
    listing = PropertyListingSerializer(read_only=True)

    class Meta:
        model = PropertyFavorite
        fields = ["id", "listing", "created_at"]


class SavedSearchSerializer(serializers.ModelSerializer):
    class Meta:
        model = SavedSearch
        fields = ["id", "name", "filters", "active", "created_at", "updated_at"]
        read_only_fields = ["id", "created_at", "updated_at"]


class PropertyVerificationEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = PropertyVerificationEvent
        fields = ["id", "from_status", "to_status", "actor", "notes", "created_at"]


class ViewingPassPlanSerializer(serializers.Serializer):
    code = serializers.CharField()
    name = serializers.CharField()
    description = serializers.CharField()
    amount_minor = serializers.IntegerField()
    currency = serializers.CharField()
    listing_quota = serializers.IntegerField()
    duration_days = serializers.IntegerField()


class PropertyViewingPassSerializer(serializers.ModelSerializer):
    listing_id = serializers.UUIDField(source="listing.id", read_only=True, allow_null=True)

    class Meta:
        model = PropertyViewingPass
        fields = [
            "id",
            "listing_id",
            "plan_code",
            "status",
            "amount_minor",
            "currency",
            "payment_ref",
            "qr_token",
            "listings_unlocked",
            "unlock_address",
            "unlock_navigation",
            "unlock_contact",
            "unlock_scheduling",
            "expires_at",
            "created_at",
        ]
        read_only_fields = fields


class PropertyLiveSessionSerializer(serializers.ModelSerializer):
    listing_id = serializers.UUIDField(source="listing.id", read_only=True)
    listing_title = serializers.CharField(source="listing.title", read_only=True)

    class Meta:
        model = PropertyLiveSession
        fields = [
            "id",
            "listing_id",
            "listing_title",
            "customer_principal",
            "owner_principal",
            "status",
            "scheduled_at",
            "started_at",
            "ended_at",
            "join_code",
            "stream_url",
            "recording_url",
            "ai_transcript",
            "appointment_notes",
            "created_at",
        ]


class PropertyLiveMessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = PropertyLiveMessage
        fields = ["id", "sender_principal", "body", "created_at"]


class PropertyWingaProfileSerializer(serializers.Serializer):
    id = serializers.CharField()
    principal = serializers.CharField()
    display_name = serializers.CharField()
    certification = serializers.CharField()
    reputation_score_e4 = serializers.IntegerField()
    trust_stars = serializers.IntegerField()
    bio = serializers.CharField(required=False, allow_blank=True)


class PropertyTimelineEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = PropertyTimelineEvent
        fields = ["id", "event_type", "title", "notes", "actor", "metadata", "created_at"]


class PropertySharedDocumentSerializer(serializers.ModelSerializer):
    class Meta:
        model = PropertySharedDocument
        fields = ["id", "title", "url", "shared_by", "created_at"]


class PropertyViewingAppointmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = PropertyViewingAppointment
        fields = ["id", "scheduled_at", "status", "location_notes", "created_at"]


class PropertyWingaAssignmentSerializer(serializers.ModelSerializer):
    listing_id = serializers.UUIDField(source="listing.id", read_only=True)
    listing_title = serializers.CharField(source="listing.title", read_only=True)
    winga = serializers.SerializerMethodField()

    class Meta:
        model = PropertyWingaAssignment
        fields = [
            "id",
            "listing_id",
            "listing_title",
            "customer_principal",
            "winga_principal",
            "winga_profile_id",
            "winga",
            "status",
            "chat_thread_id",
            "notes",
            "created_at",
        ]

    def get_winga(self, obj: PropertyWingaAssignment) -> dict:
        from . import human_winga

        return human_winga.winga_profile_payload(obj.winga_profile_id)


class PropertyWingaAssignmentDetailSerializer(PropertyWingaAssignmentSerializer):
    timeline = PropertyTimelineEventSerializer(many=True, read_only=True)
    documents = PropertySharedDocumentSerializer(many=True, read_only=True)
    appointments = PropertyViewingAppointmentSerializer(many=True, read_only=True)
    commission_preview = serializers.SerializerMethodField()

    class Meta(PropertyWingaAssignmentSerializer.Meta):
        fields = PropertyWingaAssignmentSerializer.Meta.fields + [
            "timeline",
            "documents",
            "appointments",
            "commission_preview",
        ]

    def get_commission_preview(self, obj: PropertyWingaAssignment) -> dict:
        from . import human_winga

        return human_winga.commission_preview(amount_minor=obj.listing.price_minor)


class CopilotChatSerializer(serializers.Serializer):
    query = serializers.CharField()
    listing_id = serializers.UUIDField(required=False, allow_null=True)


class NegotiationAssistSerializer(serializers.Serializer):
    offer_minor = serializers.IntegerField(min_value=0)


class RelocationAssistSerializer(serializers.Serializer):
    destination = serializers.CharField()


class ShareDocumentSerializer(serializers.Serializer):
    title = serializers.CharField()
    url = serializers.URLField()


class ScheduleAppointmentSerializer(serializers.Serializer):
    scheduled_at = serializers.DateTimeField()
    location_notes = serializers.CharField(required=False, allow_blank=True, default="")


class ChatMessagePostSerializer(serializers.Serializer):
    text = serializers.CharField()


class PropertyApplicationCreateSerializer(serializers.Serializer):
    employment_status = serializers.CharField(required=False, allow_blank=True, default="")
    monthly_income_minor = serializers.IntegerField(min_value=0, default=0)
    national_id = serializers.CharField(required=False, allow_blank=True, default="")
    move_in_date = serializers.DateField(required=False, allow_null=True)
    notes = serializers.CharField(required=False, allow_blank=True, default="")


class PropertyApplicationDocumentSerializer(serializers.Serializer):
    kind = serializers.CharField(required=False, default="other")
    title = serializers.CharField()
    url = serializers.URLField()


class PropertyApplicationSerializer(serializers.Serializer):
    id = serializers.UUIDField()
    listing_id = serializers.UUIDField()
    listing_title = serializers.CharField()
    status = serializers.CharField()
    employment_status = serializers.CharField()
    monthly_income_minor = serializers.IntegerField()
    national_id_masked = serializers.CharField()
    move_in_date = serializers.CharField(allow_null=True)
    notes = serializers.CharField()
    submitted_at = serializers.CharField(allow_null=True)
    verifications = serializers.DictField()
    documents = serializers.ListField()
    ready_for_approval = serializers.BooleanField()
    created_at = serializers.CharField()
    lease = serializers.DictField(required=False)


class PropertyLeaseSerializer(serializers.Serializer):
    id = serializers.UUIDField()
    application_id = serializers.UUIDField()
    listing_id = serializers.UUIDField()
    status = serializers.CharField()
    rent_minor = serializers.IntegerField()
    deposit_minor = serializers.IntegerField()
    currency = serializers.CharField()
    start_date = serializers.CharField()
    end_date = serializers.CharField()
    contract_text = serializers.CharField()
    contract_url = serializers.CharField()
    tenant_signed_at = serializers.CharField(allow_null=True)
    owner_signed_at = serializers.CharField(allow_null=True)
    payments = serializers.ListField()
    move_workflows = serializers.ListField()


class ScheduleMoveSerializer(serializers.Serializer):
    phase = serializers.ChoiceField(choices=["move_in", "move_out"])
    scheduled_at = serializers.DateTimeField()
    notes = serializers.CharField(required=False, allow_blank=True, default="")


class ReportListingSerializer(serializers.Serializer):
    reason = serializers.CharField()
    notes = serializers.CharField(required=False, allow_blank=True, default="")


class ResolveModerationSerializer(serializers.Serializer):
    action = serializers.ChoiceField(choices=["dismiss", "suspend_listing", "review"])
    notes = serializers.CharField(required=False, allow_blank=True, default="")


class OpenDisputeSerializer(serializers.Serializer):
    subject_type = serializers.ChoiceField(choices=["lease", "application", "listing"])
    subject_id = serializers.UUIDField()
    reason = serializers.CharField()


class ResolveDisputeSerializer(serializers.Serializer):
    resolution = serializers.CharField()
    approve = serializers.BooleanField(default=True)


class AssignDisputeSerializer(serializers.Serializer):
    ops_principal = serializers.CharField()
