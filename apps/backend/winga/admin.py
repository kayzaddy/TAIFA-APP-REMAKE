from django.contrib import admin

from . import models

admin.site.register(models.BrokerageDomain)
admin.site.register(models.Category)
admin.site.register(models.WingaProfile)
admin.site.register(models.ProviderProfile)
admin.site.register(models.Offering)
admin.site.register(models.CommissionRule)
admin.site.register(models.Lead)
admin.site.register(models.Quotation)
admin.site.register(models.BrokerageDeal)
admin.site.register(models.CommissionEvent)
admin.site.register(models.Review)
admin.site.register(models.Dispute)
