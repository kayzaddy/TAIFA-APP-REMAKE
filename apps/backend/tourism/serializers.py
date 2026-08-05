from rest_framework import serializers


class TourismTripCreateSerializer(serializers.Serializer):
    title = serializers.CharField(max_length=160, required=False, default="My Tanzania trip")
    party_size = serializers.IntegerField(min_value=1, max_value=20, default=2)
    budget_tier = serializers.ChoiceField(
        choices=["budget", "mid", "luxury"], required=False, default="mid"
    )
    travel_style = serializers.CharField(max_length=32, required=False, default="leisure")
    interests = serializers.ListField(child=serializers.CharField(), required=False, default=list)
    start_date = serializers.DateField(required=False, allow_null=True)
    end_date = serializers.DateField(required=False, allow_null=True)


class TourismTripPlanSerializer(serializers.Serializer):
    party_size = serializers.IntegerField(min_value=1, max_value=20, required=False)
    budget_tier = serializers.ChoiceField(
        choices=["budget", "mid", "luxury"], required=False
    )
    travel_style = serializers.CharField(max_length=32, required=False)
    interests = serializers.ListField(child=serializers.CharField(), required=False)
    start_date = serializers.DateField(required=False, allow_null=True)
    end_date = serializers.DateField(required=False, allow_null=True)


class TourismAttachBookingSerializer(serializers.Serializer):
    booking_type = serializers.ChoiceField(choices=["tour", "stay"])
    booking_id = serializers.UUIDField()


class TourismCartBuildSerializer(serializers.Serializer):
    include_insurance_quote = serializers.BooleanField(required=False, default=True)
    include_esim_quote = serializers.BooleanField(required=False, default=True)
    esim_plan_id = serializers.CharField(required=False, default="esim-7d-5gb")


class TourismCheckoutCreateSerializer(serializers.Serializer):
    include_insurance = serializers.BooleanField(required=False, default=False)
    insurance_plan_id = serializers.CharField(required=False, default="ins-travel")
    include_esim = serializers.BooleanField(required=False, default=False)
    esim_plan_id = serializers.CharField(required=False, default="esim-7d-5gb")


class TourismEsimQuoteSerializer(serializers.Serializer):
    plan_id = serializers.CharField(required=False, default="esim-7d-5gb")


class TourismAssistSosSerializer(serializers.Serializer):
    trip_id = serializers.UUIDField(required=False, allow_null=True)
    latitude = serializers.FloatField(required=False, allow_null=True)
    longitude = serializers.FloatField(required=False, allow_null=True)
    notes = serializers.CharField(required=False, allow_blank=True, default="", max_length=500)
