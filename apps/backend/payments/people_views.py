"""Phone lookup, device profile (phone + display name), and saved contacts."""
from __future__ import annotations

from django.conf import settings
from django.db import IntegrityError
from drf_spectacular.utils import extend_schema
from rest_framework import serializers, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .auth import IsDevice
from .models import Contact, Device
from .people import normalize_phone


class DeviceProfileSerializer(serializers.Serializer):
    phone_number = serializers.CharField(max_length=20, required=False, allow_blank=True)
    display_name = serializers.CharField(max_length=128, required=False, allow_blank=True)


class DeviceProfileResponseSerializer(serializers.Serializer):
    owner = serializers.CharField()
    display_name = serializers.CharField()
    phone_number = serializers.CharField(allow_blank=True)


@extend_schema(
    tags=["social-payments"],
    request=DeviceProfileSerializer,
    responses={200: DeviceProfileResponseSerializer},
    summary="Set my phone number / display name so others can find and pay me",
)
class DeviceProfileView(APIView):
    """POST /api/v1/auth/device/profile — makes this wallet findable by phone.

    A device only becomes payable-by-phone once its owner sets a number here;
    until then it can still send/receive via payment links, QR, and the raw
    `owner` handle, just not phone lookup.
    """

    permission_classes = [IsDevice]

    def post(self, request):
        s = DeviceProfileSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        device: Device = request.auth
        d = s.validated_data
        if "phone_number" in d:
            phone = normalize_phone(d["phone_number"]) if d["phone_number"] else None
            if phone and Device.objects.exclude(pk=device.pk).filter(phone_number=phone).exists():
                return Response({"detail": "That phone number is already linked to another wallet."}, status=409)
            device.phone_number = phone
        if "display_name" in d:
            device.label = d["display_name"]
        try:
            device.save(update_fields=["phone_number", "label", "last_seen_at"])
        except IntegrityError:
            return Response({"detail": "That phone number is already linked to another wallet."}, status=409)
        return Response(
            {
                "owner": device.owner,
                "display_name": device.label,
                "phone_number": device.phone_number or "",
            }
        )


class MerchantStatusSerializer(serializers.Serializer):
    enable = serializers.BooleanField()


class MerchantStatusResponseSerializer(serializers.Serializer):
    is_merchant = serializers.BooleanField()
    fee_bps = serializers.IntegerField()


@extend_schema(
    tags=["social-payments"],
    request=MerchantStatusSerializer,
    responses={200: MerchantStatusResponseSerializer},
    summary="Turn merchant mode on/off (fee applies to payment links you create afterwards)",
)
class MerchantStatusView(APIView):
    """POST /api/v1/auth/device/merchant — self-service merchant opt-in.

    Enabling this does not change anything retroactively: only payment links
    created *after* opting in carry the platform fee (snapshotted at creation
    in `PaymentLink.fee_bps`). P2P transfers/requests/splits are never fee'd.
    """

    permission_classes = [IsDevice]

    def post(self, request):
        s = MerchantStatusSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        device: Device = request.auth
        device.is_merchant = s.validated_data["enable"]
        device.save(update_fields=["is_merchant", "last_seen_at"])
        return Response(
            {
                "is_merchant": device.is_merchant,
                "fee_bps": settings.PAYMENTS_MERCHANT_FEE_BPS if device.is_merchant else 0,
            }
        )


class PersonSerializer(serializers.Serializer):
    owner = serializers.CharField()
    display_name = serializers.CharField(allow_blank=True)


class PhoneLookupRequestSerializer(serializers.Serializer):
    phone_number = serializers.CharField(max_length=20)


@extend_schema(
    tags=["social-payments"],
    request=PhoneLookupRequestSerializer,
    responses={200: PersonSerializer},
    summary="Find a TAIFA wallet by phone number",
)
class PeopleLookupView(APIView):
    """POST /api/v1/payments/people/lookup — resolve a phone number to a
    wallet owner + display name, for "pay a friend" pickers. Reveals only
    what's needed to address a payment — never balance or history.

    POST (not GET ?phone=) deliberately: a leading '+' in a query string is
    form-urlencoding for a space, which would silently corrupt every E.164
    number — exactly the numbers this endpoint exists to look up.
    """

    permission_classes = [IsDevice]

    def post(self, request):
        s = PhoneLookupRequestSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        phone = normalize_phone(s.validated_data["phone_number"])
        try:
            device = Device.objects.get(phone_number=phone)
        except Device.DoesNotExist:
            return Response({"detail": "No TAIFA wallet is linked to that number."}, status=404)
        if device.owner == request.auth.owner:
            return Response({"detail": "That's your own number."}, status=422)
        return Response({"owner": device.owner, "display_name": device.label or phone})


class ContactCreateSerializer(serializers.Serializer):
    phone_number = serializers.CharField(max_length=20)
    label = serializers.CharField(max_length=128, required=False, allow_blank=True, default="")


class ContactSerializer(serializers.ModelSerializer):
    class Meta:
        model = Contact
        fields = ["id", "contact_owner", "display_name", "phone_number", "favorite", "created_at"]


@extend_schema(
    tags=["social-payments"],
    request=ContactCreateSerializer,
    responses={201: ContactSerializer, 200: ContactSerializer(many=True)},
    summary="Save (POST) or list (GET) my contacts",
)
class ContactListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        contacts = Contact.objects.filter(owner=request.auth.owner)
        return Response({"contacts": ContactSerializer(contacts, many=True).data})

    def post(self, request):
        s = ContactCreateSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        d = s.validated_data
        phone = normalize_phone(d["phone_number"])
        try:
            target = Device.objects.get(phone_number=phone)
        except Device.DoesNotExist:
            return Response({"detail": "No TAIFA wallet is linked to that number."}, status=404)
        owner = request.auth.owner
        if target.owner == owner:
            return Response({"detail": "You cannot add yourself as a contact."}, status=422)
        contact, _ = Contact.objects.update_or_create(
            owner=owner,
            contact_owner=target.owner,
            defaults={
                "display_name": d.get("label") or target.label or phone,
                "phone_number": phone,
            },
        )
        return Response(ContactSerializer(contact).data, status=status.HTTP_201_CREATED)


@extend_schema(
    tags=["social-payments"], request=None, responses={204: None}, summary="Remove a saved contact"
)
class ContactDetailView(APIView):
    permission_classes = [IsDevice]

    def delete(self, request, contact_id):
        deleted, _ = Contact.objects.filter(pk=contact_id, owner=request.auth.owner).delete()
        if not deleted:
            return Response({"detail": "Not found."}, status=404)
        return Response(status=204)


@extend_schema(
    tags=["social-payments"],
    request=None,
    responses={200: ContactSerializer},
    summary="Toggle favorite on a saved contact",
    operation_id="payments_contact_action",
)
class ContactActionView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, contact_id, action):
        try:
            contact = Contact.objects.get(pk=contact_id, owner=request.auth.owner)
        except Contact.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        if action == "favorite":
            contact.favorite = True
        elif action == "unfavorite":
            contact.favorite = False
        else:
            return Response({"detail": f"Unknown action {action}."}, status=404)
        contact.save(update_fields=["favorite"])
        return Response(ContactSerializer(contact).data)
