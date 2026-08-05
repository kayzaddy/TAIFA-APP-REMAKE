from rest_framework import serializers

from .models import DriverChannelBinding


class ChannelBindingSerializer(serializers.ModelSerializer):
    driver_id = serializers.UUIDField(source="driver.id", read_only=True)
    driver_name = serializers.CharField(source="driver.full_name", read_only=True)

    class Meta:
        model = DriverChannelBinding
        fields = [
            "id",
            "driver_id",
            "driver_name",
            "msisdn",
            "device_capability",
            "has_internet",
            "has_gps",
            "preferred_channel",
            "reliability_score",
            "created_at",
            "updated_at",
        ]
        read_only_fields = fields


class TripBoardingPinVerifySerializer(serializers.Serializer):
    pin = serializers.CharField(min_length=4, max_length=12)


class TripStatusSerializer(serializers.Serializer):
    trip_id = serializers.CharField()
    status = serializers.CharField()
    message = serializers.CharField()
    driver_name = serializers.CharField(allow_blank=True)
    vehicle_label = serializers.CharField(allow_blank=True)


class TripDispatchDetailSerializer(serializers.Serializer):
    trip_id = serializers.CharField()
    trip_status = serializers.CharField()
    hybrid_sms_demo = serializers.BooleanField()
    sms_sent = serializers.BooleanField()
    sms_preview = serializers.CharField(allow_blank=True)
    sms_to = serializers.CharField(allow_blank=True)
    sms_driver_name = serializers.CharField(allow_blank=True)
    sms_offer_id = serializers.CharField(allow_blank=True)
    pending_offers = serializers.IntegerField()
    channels = serializers.ListField(child=serializers.DictField())
