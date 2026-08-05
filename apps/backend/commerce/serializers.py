from rest_framework import serializers

from .models import (
    AdminCase,
    ChatMessage,
    ChatThread,
    DriverJob,
    EduPayment,
    FamilyTransfer,
    FlightBooking,
    FoodOrder,
    GovRequest,
    HealthAppointment,
    HousingInquiry,
    HudumaBooking,
    InsurancePolicy,
    JobAssignment,
    MerchantOrder,
    StayBooking,
    TourBooking,
    WealthContribution,
    WingaOrder,
    WingaServiceBooking,
    WingaShopApplication,
)


class FoodOrderSerializer(serializers.ModelSerializer):
    class Meta:
        model = FoodOrder
        fields = [
            "id", "owner", "status", "restaurant_id", "restaurant_name",
            "subtotal_minor", "delivery_fee_minor", "total_minor", "currency",
            "courier_name", "payment_ref", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "owner", "created_at", "updated_at", "status", "payment_ref"]


class FoodOrderCreateSerializer(serializers.Serializer):
    restaurant_id = serializers.CharField()
    restaurant_name = serializers.CharField()
    subtotal_minor = serializers.IntegerField(min_value=0)
    delivery_fee_minor = serializers.IntegerField(min_value=0, default=0)
    total_minor = serializers.IntegerField(min_value=1)
    currency = serializers.CharField(default="TZS")
    courier_name = serializers.CharField(required=False, allow_blank=True, default="")


class FoodOrderPatchSerializer(serializers.Serializer):
    status = serializers.CharField(required=False)
    courier_name = serializers.CharField(required=False, allow_blank=True)

    def validate_status(self, value):
        if (value or "").strip().lower() in {
            "paid",
            "payment_confirmed",
            "deposit_paid",
        }:
            raise serializers.ValidationError(
                "paid status is server-authored; use POST …/pay with Idempotency-Key"
            )
        return value

class StayBookingSerializer(serializers.ModelSerializer):
    class Meta:
        model = StayBooking
        fields = [
            "id", "owner", "status", "hotel_id", "hotel_name", "room_name",
            "check_in", "check_out", "guests", "nights", "nightly_rate_minor",
            "taxes_minor", "total_minor", "currency", "confirmation_code",
            "payment_ref", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "owner", "created_at", "updated_at", "status", "payment_ref"]


class StayBookingCreateSerializer(serializers.Serializer):
    hotel_id = serializers.CharField()
    hotel_name = serializers.CharField()
    room_name = serializers.CharField()
    check_in = serializers.DateField()
    check_out = serializers.DateField()
    guests = serializers.IntegerField(min_value=1, default=2)
    nights = serializers.IntegerField(min_value=1, default=1)
    nightly_rate_minor = serializers.IntegerField(min_value=0)
    taxes_minor = serializers.IntegerField(min_value=0, default=0)
    total_minor = serializers.IntegerField(min_value=1)
    currency = serializers.CharField(default="TZS")
    confirmation_code = serializers.CharField(required=False, allow_blank=True, default="")


class StayBookingPatchSerializer(serializers.Serializer):
    status = serializers.CharField(required=False)
    confirmation_code = serializers.CharField(required=False, allow_blank=True)

    def validate_status(self, value):
        if (value or "").strip().lower() in {
            "paid",
            "payment_confirmed",
            "deposit_paid",
        }:
            raise serializers.ValidationError(
                "paid status is server-authored; use POST …/pay with Idempotency-Key"
            )
        return value

class FlightBookingSerializer(serializers.ModelSerializer):
    class Meta:
        model = FlightBooking
        fields = [
            "id", "owner", "status", "airline", "flight_number", "origin_code",
            "destination_code", "depart_at", "passengers", "total_minor", "currency",
            "pnr", "payment_ref", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "owner", "created_at", "updated_at", "status", "payment_ref"]


class FlightBookingCreateSerializer(serializers.Serializer):
    airline = serializers.CharField()
    flight_number = serializers.CharField()
    origin_code = serializers.CharField()
    destination_code = serializers.CharField()
    depart_at = serializers.DateTimeField()
    passengers = serializers.IntegerField(min_value=1, default=1)
    total_minor = serializers.IntegerField(min_value=1)
    currency = serializers.CharField(default="TZS")
    pnr = serializers.CharField(required=False, allow_blank=True, default="")


class FlightBookingPatchSerializer(serializers.Serializer):
    status = serializers.CharField(required=False)
    pnr = serializers.CharField(required=False, allow_blank=True)

    def validate_status(self, value):
        if (value or "").strip().lower() in {
            "paid",
            "payment_confirmed",
            "deposit_paid",
        }:
            raise serializers.ValidationError(
                "paid status is server-authored; use POST …/pay with Idempotency-Key"
            )
        return value

class TourBookingSerializer(serializers.ModelSerializer):
    class Meta:
        model = TourBooking
        fields = [
            "id", "owner", "status", "tour_id", "tour_title", "experience_date",
            "guests", "total_minor", "currency", "confirmation_code", "payment_ref",
            "created_at", "updated_at",
        ]
        read_only_fields = ["id", "owner", "created_at", "updated_at", "status", "payment_ref"]


class TourBookingCreateSerializer(serializers.Serializer):
    tour_id = serializers.CharField()
    tour_title = serializers.CharField()
    experience_date = serializers.DateField()
    guests = serializers.IntegerField(min_value=1, default=2)
    total_minor = serializers.IntegerField(min_value=1)
    currency = serializers.CharField(default="TZS")
    confirmation_code = serializers.CharField(required=False, allow_blank=True, default="")


class TourBookingPatchSerializer(serializers.Serializer):
    status = serializers.CharField(required=False)
    confirmation_code = serializers.CharField(required=False, allow_blank=True)

    def validate_status(self, value):
        if (value or "").strip().lower() in {
            "paid",
            "payment_confirmed",
            "deposit_paid",
        }:
            raise serializers.ValidationError(
                "paid status is server-authored; use POST …/pay with Idempotency-Key"
            )
        return value

class WingaOrderSerializer(serializers.ModelSerializer):
    class Meta:
        model = WingaOrder
        fields = [
            "id", "owner", "status", "total_minor", "currency", "item_count",
            "summary", "payment_ref", "courier_name", "eta_label",
            "created_at", "updated_at",
        ]
        read_only_fields = ["id", "owner", "created_at", "updated_at", "status", "payment_ref"]


class WingaOrderCreateSerializer(serializers.Serializer):
    total_minor = serializers.IntegerField(min_value=1)
    currency = serializers.CharField(default="TZS")
    item_count = serializers.IntegerField(min_value=1, default=1)
    summary = serializers.CharField(required=False, allow_blank=True, default="")
    courier_name = serializers.CharField(required=False, allow_blank=True, default="")
    eta_label = serializers.CharField(required=False, allow_blank=True, default="")


class WingaOrderPatchSerializer(serializers.Serializer):
    status = serializers.CharField(required=False)
    courier_name = serializers.CharField(required=False, allow_blank=True)
    eta_label = serializers.CharField(required=False, allow_blank=True)

    def validate_status(self, value):
        if (value or "").strip().lower() in {
            "paid",
            "payment_confirmed",
            "deposit_paid",
        }:
            raise serializers.ValidationError(
                "paid status is server-authored; use POST …/pay with Idempotency-Key"
            )
        return value

class WingaServiceBookingSerializer(serializers.ModelSerializer):
    class Meta:
        model = WingaServiceBooking
        fields = [
            "id", "owner", "service_id", "service_title", "slot_label",
            "total_minor", "currency", "payment_ref", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "owner", "created_at", "updated_at", "status", "payment_ref"]


class WingaServiceBookingCreateSerializer(serializers.Serializer):
    service_id = serializers.CharField()
    service_title = serializers.CharField()
    slot_label = serializers.CharField()
    total_minor = serializers.IntegerField(min_value=1)
    currency = serializers.CharField(default="TZS")


class WingaShopApplicationSerializer(serializers.ModelSerializer):
    class Meta:
        model = WingaShopApplication
        fields = [
            "id", "owner", "name", "category", "address", "status",
            "created_at", "updated_at",
        ]
        read_only_fields = ["id", "owner", "created_at", "updated_at"]


class WingaShopApplicationCreateSerializer(serializers.Serializer):
    name = serializers.CharField()
    category = serializers.CharField(default="Retail")
    address = serializers.CharField(required=False, allow_blank=True, default="")


class GovRequestSerializer(serializers.ModelSerializer):
    class Meta:
        model = GovRequest
        fields = [
            "id", "owner", "status", "service_id", "service_title", "agency",
            "category", "applicant_name", "fee_minor", "currency", "eta_days",
            "reference", "payment_ref", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "owner", "created_at", "updated_at", "status", "payment_ref"]


class GovRequestCreateSerializer(serializers.Serializer):
    service_id = serializers.CharField()
    service_title = serializers.CharField()
    agency = serializers.CharField(required=False, allow_blank=True, default="")
    category = serializers.CharField(required=False, allow_blank=True, default="")
    applicant_name = serializers.CharField()
    fee_minor = serializers.IntegerField(min_value=0, default=0)
    currency = serializers.CharField(default="TZS")
    eta_days = serializers.IntegerField(min_value=1, default=7)
    reference = serializers.CharField(required=False, allow_blank=True, default="")


class GovRequestPatchSerializer(serializers.Serializer):
    status = serializers.CharField(required=False)
    reference = serializers.CharField(required=False, allow_blank=True)

    def validate_status(self, value):
        if (value or "").strip().lower() in {
            "paid",
            "payment_confirmed",
            "deposit_paid",
        }:
            raise serializers.ValidationError(
                "paid status is server-authored; use POST …/pay with Idempotency-Key"
            )
        return value

class HealthAppointmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = HealthAppointment
        fields = [
            "id", "owner", "status", "facility_id", "facility_name", "specialty",
            "area", "patient_name", "slot_at", "fee_minor", "currency",
            "confirmation_code", "payment_ref", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "owner", "created_at", "updated_at", "status", "payment_ref"]


class HealthAppointmentCreateSerializer(serializers.Serializer):
    facility_id = serializers.CharField()
    facility_name = serializers.CharField()
    specialty = serializers.CharField(required=False, allow_blank=True, default="")
    area = serializers.CharField(required=False, allow_blank=True, default="")
    patient_name = serializers.CharField()
    slot_at = serializers.DateTimeField()
    fee_minor = serializers.IntegerField(min_value=0)
    currency = serializers.CharField(default="TZS")
    confirmation_code = serializers.CharField(required=False, allow_blank=True, default="")


class HealthAppointmentPatchSerializer(serializers.Serializer):
    status = serializers.CharField(required=False)
    confirmation_code = serializers.CharField(required=False, allow_blank=True)

    def validate_status(self, value):
        if (value or "").strip().lower() in {
            "paid",
            "payment_confirmed",
            "deposit_paid",
        }:
            raise serializers.ValidationError(
                "paid status is server-authored; use POST …/pay with Idempotency-Key"
            )
        return value

class EduPaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = EduPayment
        fields = [
            "id", "owner", "status", "school_id", "school_name", "level", "area",
            "student_name", "amount_minor", "currency", "invoice_no", "payment_ref",
            "created_at", "updated_at",
        ]
        read_only_fields = ["id", "owner", "created_at", "updated_at", "status", "payment_ref"]


class EduPaymentCreateSerializer(serializers.Serializer):
    school_id = serializers.CharField()
    school_name = serializers.CharField()
    level = serializers.CharField(required=False, allow_blank=True, default="")
    area = serializers.CharField(required=False, allow_blank=True, default="")
    student_name = serializers.CharField()
    amount_minor = serializers.IntegerField(min_value=1)
    currency = serializers.CharField(default="TZS")
    invoice_no = serializers.CharField(required=False, allow_blank=True, default="")


class EduPaymentPatchSerializer(serializers.Serializer):
    status = serializers.CharField(required=False)
    invoice_no = serializers.CharField(required=False, allow_blank=True)

    def validate_status(self, value):
        if (value or "").strip().lower() in {
            "paid",
            "payment_confirmed",
            "deposit_paid",
        }:
            raise serializers.ValidationError(
                "paid status is server-authored; use POST …/pay with Idempotency-Key"
            )
        return value

class HousingInquirySerializer(serializers.ModelSerializer):
    class Meta:
        model = HousingInquiry
        fields = [
            "id", "owner", "status", "listing_id", "listing_title", "area",
            "beds", "baths", "monthly_rent_minor", "deposit_minor", "currency",
            "viewing_at", "payment_ref", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "owner", "created_at", "updated_at", "status", "payment_ref"]


class HousingInquiryCreateSerializer(serializers.Serializer):
    listing_id = serializers.CharField()
    listing_title = serializers.CharField()
    area = serializers.CharField(required=False, allow_blank=True, default="")
    beds = serializers.IntegerField(min_value=0, default=1)
    baths = serializers.IntegerField(min_value=0, default=1)
    monthly_rent_minor = serializers.IntegerField(min_value=0)
    deposit_minor = serializers.IntegerField(min_value=0)
    currency = serializers.CharField(default="TZS")
    viewing_at = serializers.DateTimeField(required=False, allow_null=True)


class HousingInquiryPatchSerializer(serializers.Serializer):
    status = serializers.CharField(required=False)
    viewing_at = serializers.DateTimeField(required=False, allow_null=True)

    def validate_status(self, value):
        if (value or "").strip().lower() in {
            "paid",
            "payment_confirmed",
            "deposit_paid",
        }:
            raise serializers.ValidationError(
                "paid status is server-authored; use POST …/pay with Idempotency-Key"
            )
        return value

class WealthContributionSerializer(serializers.ModelSerializer):
    class Meta:
        model = WealthContribution
        fields = [
            "id", "owner", "status", "circle_id", "circle_name", "purpose",
            "amount_minor", "currency", "payment_ref", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "owner", "created_at", "updated_at", "status", "payment_ref"]


class WealthContributionCreateSerializer(serializers.Serializer):
    circle_id = serializers.CharField()
    circle_name = serializers.CharField()
    purpose = serializers.CharField(required=False, allow_blank=True, default="")
    amount_minor = serializers.IntegerField(min_value=1)
    currency = serializers.CharField(default="TZS")
    status = serializers.CharField(required=False, default="paid")


class WealthContributionPatchSerializer(serializers.Serializer):
    status = serializers.CharField(required=False)

    def validate_status(self, value):
        if (value or "").strip().lower() in {
            "paid",
            "payment_confirmed",
            "deposit_paid",
        }:
            raise serializers.ValidationError(
                "paid status is server-authored; use POST …/pay with Idempotency-Key"
            )
        return value

class JobAssignmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = JobAssignment
        fields = [
            "id", "owner", "status", "job_id", "job_title", "area", "kind",
            "summary", "pay_minor", "currency", "payment_ref", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "owner", "created_at", "updated_at", "status", "payment_ref"]


class JobAssignmentCreateSerializer(serializers.Serializer):
    job_id = serializers.CharField()
    job_title = serializers.CharField()
    area = serializers.CharField(required=False, allow_blank=True, default="")
    kind = serializers.CharField(default="gig")
    summary = serializers.CharField(required=False, allow_blank=True, default="")
    pay_minor = serializers.IntegerField(min_value=0)
    currency = serializers.CharField(default="TZS")


class JobAssignmentPatchSerializer(serializers.Serializer):
    status = serializers.CharField(required=False)

    def validate_status(self, value):
        if (value or "").strip().lower() in {
            "paid",
            "payment_confirmed",
            "deposit_paid",
        }:
            raise serializers.ValidationError(
                "paid status is server-authored; use POST …/pay with Idempotency-Key"
            )
        return value

class InsurancePolicySerializer(serializers.ModelSerializer):
    class Meta:
        model = InsurancePolicy
        fields = [
            "id", "owner", "status", "plan_id", "plan_name", "provider", "category",
            "premium_minor", "coverage_minor", "currency", "policy_ref",
            "created_at", "updated_at",
        ]
        read_only_fields = ["id", "owner", "created_at", "updated_at"]


class InsurancePolicyCreateSerializer(serializers.Serializer):
    plan_id = serializers.CharField()
    plan_name = serializers.CharField()
    provider = serializers.CharField(required=False, allow_blank=True, default="")
    category = serializers.CharField(required=False, allow_blank=True, default="")
    premium_minor = serializers.IntegerField(min_value=0)
    coverage_minor = serializers.IntegerField(min_value=0, default=0)
    currency = serializers.CharField(default="TZS")
    policy_ref = serializers.CharField(required=False, allow_blank=True, default="")


class InsurancePolicyPatchSerializer(serializers.Serializer):
    status = serializers.CharField(required=False)
    policy_ref = serializers.CharField(required=False, allow_blank=True)

    def validate_status(self, value):
        if (value or "").strip().lower() in {
            "paid",
            "payment_confirmed",
            "deposit_paid",
        }:
            raise serializers.ValidationError(
                "paid status is server-authored; use POST …/pay with Idempotency-Key"
            )
        return value

class FamilyTransferSerializer(serializers.ModelSerializer):
    class Meta:
        model = FamilyTransfer
        fields = [
            "id", "owner", "status", "member_id", "member_name", "member_role",
            "member_phone", "kind", "amount_minor", "currency", "note", "payment_ref",
            "created_at", "updated_at",
        ]
        read_only_fields = ["id", "owner", "created_at", "updated_at", "status", "payment_ref"]


class FamilyTransferCreateSerializer(serializers.Serializer):
    member_id = serializers.CharField()
    member_name = serializers.CharField()
    member_role = serializers.CharField(required=False, allow_blank=True, default="")
    member_phone = serializers.CharField(required=False, allow_blank=True, default="")
    kind = serializers.CharField(default="send")
    amount_minor = serializers.IntegerField(min_value=1)
    currency = serializers.CharField(default="TZS")
    note = serializers.CharField(required=False, allow_blank=True, default="")
    status = serializers.CharField(required=False, default="paid")


class FamilyTransferPatchSerializer(serializers.Serializer):
    status = serializers.CharField(required=False)

    def validate_status(self, value):
        if (value or "").strip().lower() in {
            "paid",
            "payment_confirmed",
            "deposit_paid",
        }:
            raise serializers.ValidationError(
                "paid status is server-authored; use POST …/pay with Idempotency-Key"
            )
        return value

class HudumaBookingSerializer(serializers.ModelSerializer):
    class Meta:
        model = HudumaBooking
        fields = [
            "id", "owner", "status", "service_id", "service_title", "category",
            "provider", "slot_label", "price_minor", "currency", "payment_ref",
            "created_at", "updated_at",
        ]
        read_only_fields = ["id", "owner", "created_at", "updated_at", "status", "payment_ref"]


class HudumaBookingCreateSerializer(serializers.Serializer):
    service_id = serializers.CharField()
    service_title = serializers.CharField()
    category = serializers.CharField(required=False, allow_blank=True, default="")
    provider = serializers.CharField(required=False, allow_blank=True, default="")
    slot_label = serializers.CharField()
    price_minor = serializers.IntegerField(min_value=0)
    currency = serializers.CharField(default="TZS")
    status = serializers.CharField(required=False, default="paid")


class HudumaBookingPatchSerializer(serializers.Serializer):
    status = serializers.CharField(required=False)

    def validate_status(self, value):
        if (value or "").strip().lower() in {
            "paid",
            "payment_confirmed",
            "deposit_paid",
        }:
            raise serializers.ValidationError(
                "paid status is server-authored; use POST …/pay with Idempotency-Key"
            )
        return value

class MerchantOrderSerializer(serializers.ModelSerializer):
    class Meta:
        model = MerchantOrder
        fields = [
            "id", "owner", "status", "customer_name", "items_label",
            "total_minor", "currency", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "owner", "created_at", "updated_at"]


class MerchantOrderCreateSerializer(serializers.Serializer):
    customer_name = serializers.CharField()
    items_label = serializers.CharField()
    total_minor = serializers.IntegerField(min_value=0)
    currency = serializers.CharField(default="TZS")
    status = serializers.CharField(required=False, default="new")


class MerchantOrderPatchSerializer(serializers.Serializer):
    status = serializers.CharField(required=False)

    def validate_status(self, value):
        if (value or "").strip().lower() in {
            "paid",
            "payment_confirmed",
            "deposit_paid",
        }:
            raise serializers.ValidationError(
                "paid status is server-authored; use POST …/pay with Idempotency-Key"
            )
        return value

class DriverJobSerializer(serializers.ModelSerializer):
    class Meta:
        model = DriverJob
        fields = [
            "id", "owner", "status", "rider_name", "pickup", "dropoff",
            "fare_minor", "currency", "eta_minutes", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "owner", "created_at", "updated_at"]


class DriverJobCreateSerializer(serializers.Serializer):
    rider_name = serializers.CharField()
    pickup = serializers.CharField()
    dropoff = serializers.CharField()
    fare_minor = serializers.IntegerField(min_value=0)
    currency = serializers.CharField(default="TZS")
    eta_minutes = serializers.IntegerField(min_value=1, default=5)
    status = serializers.CharField(required=False, default="offered")


class DriverJobPatchSerializer(serializers.Serializer):
    status = serializers.CharField(required=False)

    def validate_status(self, value):
        if (value or "").strip().lower() in {
            "paid",
            "payment_confirmed",
            "deposit_paid",
        }:
            raise serializers.ValidationError(
                "paid status is server-authored; use POST …/pay with Idempotency-Key"
            )
        return value

class ChatThreadSerializer(serializers.ModelSerializer):
    class Meta:
        model = ChatThread
        fields = [
            "id", "owner", "title", "subtitle", "unread", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "owner", "created_at", "updated_at"]


class ChatThreadCreateSerializer(serializers.Serializer):
    title = serializers.CharField()
    subtitle = serializers.CharField(required=False, allow_blank=True, default="")
    unread = serializers.IntegerField(min_value=0, default=0)


class ChatThreadPatchSerializer(serializers.Serializer):
    title = serializers.CharField(required=False)
    subtitle = serializers.CharField(required=False, allow_blank=True)
    unread = serializers.IntegerField(min_value=0, required=False)


class ChatMessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ChatMessage
        fields = ["id", "owner", "thread", "sender", "text", "created_at"]
        read_only_fields = ["id", "owner", "thread", "created_at"]


class ChatMessageCreateSerializer(serializers.Serializer):
    sender = serializers.CharField(default="me")
    text = serializers.CharField()


class AdminCaseSerializer(serializers.ModelSerializer):
    class Meta:
        model = AdminCase
        fields = [
            "id", "owner", "kind", "status", "title", "subject", "detail",
            "created_at", "updated_at",
        ]
        read_only_fields = ["id", "owner", "created_at", "updated_at"]


class AdminCaseCreateSerializer(serializers.Serializer):
    kind = serializers.CharField(default="kyc")
    status = serializers.CharField(required=False, default="open")
    title = serializers.CharField()
    subject = serializers.CharField()
    detail = serializers.CharField(required=False, allow_blank=True, default="")


class AdminCasePatchSerializer(serializers.Serializer):
    status = serializers.CharField(required=False)

    def validate_status(self, value):
        if (value or "").strip().lower() in {
            "paid",
            "payment_confirmed",
            "deposit_paid",
        }:
            raise serializers.ValidationError(
                "paid status is server-authored; use POST …/pay with Idempotency-Key"
            )
        return value

