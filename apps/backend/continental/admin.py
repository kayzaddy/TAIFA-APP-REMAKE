from django.contrib import admin

from . import models

for model in (
    models.CountryProfile,
    models.ComplianceProfile,
    models.PaymentRailBinding,
    models.IdentityFederationBinding,
    models.LanguagePack,
    models.FxRate,
    models.CrossBorderCorridor,
    models.PartnerNetworkMember,
    models.DataResidencyPolicy,
):
    admin.site.register(model)
