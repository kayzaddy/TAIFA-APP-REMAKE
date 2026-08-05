from django.contrib import admin

from . import models

for model in (
    models.ModelRegistryEntry,
    models.DatasetRegistryEntry,
    models.CapabilityDefinition,
    models.AgentDefinition,
    models.KnowledgeDocument,
    models.AiDecision,
    models.AutomationRule,
    models.SafetyEvent,
):
    admin.site.register(model)
