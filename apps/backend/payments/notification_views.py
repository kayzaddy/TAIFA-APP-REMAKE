"""Notification inbox API — read what `payments.notifications.notify()` queued."""
from __future__ import annotations

from drf_spectacular.utils import extend_schema
from rest_framework import serializers
from rest_framework.response import Response
from rest_framework.views import APIView

from .auth import IsDevice
from .models import PushNotification


class PushNotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = PushNotification
        fields = ["id", "title", "body", "data", "status", "read", "created_at", "sent_at"]


@extend_schema(
    tags=["social-payments"],
    responses={200: PushNotificationSerializer(many=True)},
    summary="My notification inbox (money requests, bill shares, link payments, ...)",
)
class NotificationListView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        owner = request.auth.owner
        notes = PushNotification.objects.filter(owner=owner)[:100]
        unread_count = PushNotification.objects.filter(owner=owner, read=False).count()
        return Response(
            {
                "unread_count": unread_count,
                "notifications": PushNotificationSerializer(notes, many=True).data,
            }
        )


@extend_schema(
    tags=["social-payments"],
    request=None,
    responses={200: PushNotificationSerializer},
    summary="Mark a notification as read",
)
class NotificationMarkReadView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, notification_id):
        try:
            note = PushNotification.objects.get(pk=notification_id, owner=request.auth.owner)
        except PushNotification.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        if not note.read:
            note.read = True
            note.save(update_fields=["read"])
        return Response(PushNotificationSerializer(note).data)
