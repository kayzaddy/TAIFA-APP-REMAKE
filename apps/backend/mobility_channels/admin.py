from django.contrib import admin

from . import models


@admin.register(models.DriverChannelBinding)
class DriverChannelBindingAdmin(admin.ModelAdmin):
    list_display = ("driver", "device_capability", "msisdn", "has_internet", "has_gps")
    search_fields = ("driver__full_name", "msisdn")


@admin.register(models.ChannelDispatchAttempt)
class ChannelDispatchAttemptAdmin(admin.ModelAdmin):
    list_display = ("trip", "driver", "channel", "status", "created_at")
    list_filter = ("channel", "status")


admin.site.register(models.InboundMessage)
admin.site.register(models.UssdSession)
admin.site.register(models.TripBoardingPin)
