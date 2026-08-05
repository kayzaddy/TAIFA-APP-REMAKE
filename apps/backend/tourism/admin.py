from django.contrib import admin

from .models import TourismItineraryVersion, TourismTrip


@admin.register(TourismTrip)
class TourismTripAdmin(admin.ModelAdmin):
    list_display = ("id", "owner", "title", "status", "updated_at")
    list_filter = ("status",)
    search_fields = ("owner", "title")


@admin.register(TourismItineraryVersion)
class TourismItineraryVersionAdmin(admin.ModelAdmin):
    list_display = ("id", "trip", "version", "label", "estimate_minor")
