from django.contrib import admin

from . import models

admin.site.register(models.SharedService)
admin.site.register(models.IndustryDomain)
admin.site.register(models.SuperAppModule)
admin.site.register(models.PrincipalModuleEnablement)
admin.site.register(models.EcosystemWorkflowBinding)
admin.site.register(models.AiCapability)
admin.site.register(models.WebhookSubscription)
admin.site.register(models.PartnerApplication)
admin.site.register(models.AgricultureFarm)
admin.site.register(models.AgricultureListing)
