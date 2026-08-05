"""TAIFA AI OS — models for inference, knowledge, agents, and governance.

Never stores payment ledger state. Decisions are advisory unless a human
approval workflow completes through enterprise.workflow.
"""
from __future__ import annotations

import uuid

from django.db import models
from django.utils import timezone


class ModelRegistryEntry(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.SlugField(max_length=64, unique=True)
    name = models.CharField(max_length=128)
    modality = models.CharField(max_length=32, default="text")  # text|vision|speech|multimodal|tabular
    version = models.CharField(max_length=32, default="1.0.0")
    status = models.CharField(max_length=16, default="active")  # active|canary|retired|failed
    adapter_path = models.CharField(max_length=255, default="ai_os.adapters.StubInferenceAdapter")
    metrics = models.JSONField(default=dict, blank=True)  # latency_p50, accuracy_e4, …
    deployment = models.CharField(max_length=32, default="hybrid")  # cloud|onprem|hybrid
    rollback_to = models.CharField(max_length=32, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)


class DatasetRegistryEntry(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.SlugField(max_length=64, unique=True)
    name = models.CharField(max_length=128)
    domain_code = models.CharField(max_length=64, blank=True, default="")
    purpose = models.CharField(max_length=64, default="training")  # training|eval|reference
    schema_ref = models.CharField(max_length=255, blank=True, default="")
    pii_class = models.CharField(max_length=16, default="none")  # none|masked|restricted
    row_count = models.PositiveBigIntegerField(default=0)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)


class FeatureStoreEntry(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    entity_type = models.CharField(max_length=64, db_index=True)
    entity_id = models.CharField(max_length=128, db_index=True)
    feature_set = models.CharField(max_length=64, db_index=True)
    features = models.JSONField(default=dict)
    as_of = models.DateTimeField(default=timezone.now, db_index=True)
    model_version = models.CharField(max_length=32, blank=True, default="")

    class Meta:
        indexes = [
            models.Index(fields=["entity_type", "entity_id", "feature_set", "-as_of"]),
        ]


class VectorDocument(models.Model):
    """Lightweight vector store — embedding stored as JSON float list for portability."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    collection = models.CharField(max_length=64, db_index=True)
    external_id = models.CharField(max_length=128, blank=True, default="")
    text = models.TextField()
    embedding = models.JSONField(default=list)  # list[float]
    metadata = models.JSONField(default=dict, blank=True)
    domain_code = models.CharField(max_length=64, blank=True, default="", db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [models.Index(fields=["collection", "domain_code"])]


class KnowledgeDocument(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.SlugField(max_length=96, unique=True)
    title = models.CharField(max_length=255)
    category = models.CharField(max_length=64, db_index=True)  # policy|regulation|manual|medical|transport|…
    domain_code = models.CharField(max_length=64, blank=True, default="", db_index=True)
    body = models.TextField()
    source_uri = models.CharField(max_length=512, blank=True, default="")
    citation = models.CharField(max_length=255, blank=True, default="")
    language = models.CharField(max_length=16, default="en")
    active = models.BooleanField(default=True)
    metadata = models.JSONField(default=dict, blank=True)
    indexed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)


class CapabilityDefinition(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.SlugField(max_length=64, unique=True)
    name = models.CharField(max_length=128)
    family = models.CharField(max_length=32, db_index=True)  # nlp|vision|speech|reco|risk|forecast|…
    description = models.TextField(blank=True, default="")
    model = models.ForeignKey(
        ModelRegistryEntry,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="capabilities",
    )
    requires_human_approval = models.BooleanField(default=False)
    approval_workflow_code = models.CharField(max_length=64, blank=True, default="")
    pii_policy = models.CharField(max_length=16, default="redact")  # allow|redact|deny
    status = models.CharField(max_length=16, default="available")
    input_schema = models.JSONField(default=dict, blank=True)
    output_schema = models.JSONField(default=dict, blank=True)


class AgentDefinition(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.SlugField(max_length=64, unique=True)
    name = models.CharField(max_length=128)
    domain_code = models.CharField(max_length=64, db_index=True)
    description = models.TextField(blank=True, default="")
    capabilities = models.JSONField(default=list)  # capability codes
    system_prompt = models.TextField(blank=True, default="")
    active = models.BooleanField(default=True)
    metadata = models.JSONField(default=dict, blank=True)


class AiDecision(models.Model):
    """Auditable AI decision envelope — every recommendation leaves a trail."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    principal = models.CharField(max_length=128, db_index=True)
    domain_code = models.CharField(max_length=64, blank=True, default="", db_index=True)
    agent_code = models.CharField(max_length=64, blank=True, default="")
    capability_code = models.CharField(max_length=64, db_index=True)
    model_version = models.CharField(max_length=64, default="")
    request_payload = models.JSONField(default=dict)
    result = models.JSONField(default=dict)
    confidence_e4 = models.PositiveIntegerField(default=0)
    reasoning_summary = models.TextField(blank=True, default="")
    evidence = models.JSONField(default=list, blank=True)
    requires_human_approval = models.BooleanField(default=False)
    approval_status = models.CharField(
        max_length=16, default="not_required"
    )  # not_required|pending|approved|denied
    workflow_instance_id = models.UUIDField(null=True, blank=True)
    safety = models.JSONField(default=dict, blank=True)
    latency_ms = models.PositiveIntegerField(default=0)
    token_estimate = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)


class AutomationRule(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.SlugField(max_length=64, unique=True)
    name = models.CharField(max_length=128)
    domain_code = models.CharField(max_length=64, blank=True, default="")
    trigger_event = models.CharField(max_length=64)  # document.uploaded|ticket.created|…
    capability_code = models.CharField(max_length=64)
    auto_apply = models.BooleanField(default=False)  # False = draft only
    active = models.BooleanField(default=True)
    config = models.JSONField(default=dict, blank=True)


class AutomationRun(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    rule = models.ForeignKey(AutomationRule, on_delete=models.CASCADE, related_name="runs")
    decision = models.ForeignKey(
        AiDecision, null=True, blank=True, on_delete=models.SET_NULL, related_name="automation_runs"
    )
    status = models.CharField(max_length=16, default="completed")
    output = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)


class SafetyEvent(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    kind = models.CharField(max_length=32, db_index=True)  # injection|pii|hallucination|bias|policy
    severity = models.CharField(max_length=16, default="medium")
    principal = models.CharField(max_length=128, blank=True, default="")
    decision = models.ForeignKey(
        AiDecision, null=True, blank=True, on_delete=models.SET_NULL, related_name="safety_events"
    )
    detail = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)


class InferenceMetricDaily(models.Model):
    date = models.DateField(db_index=True)
    capability_code = models.CharField(max_length=64, db_index=True)
    domain_code = models.CharField(max_length=64, blank=True, default="")
    invocations = models.PositiveBigIntegerField(default=0)
    errors = models.PositiveBigIntegerField(default=0)
    latency_sum_ms = models.PositiveBigIntegerField(default=0)
    token_sum = models.PositiveBigIntegerField(default=0)
    approval_pending = models.PositiveIntegerField(default=0)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["date", "capability_code", "domain_code"],
                name="taifa_ai_os_unique_daily_metric",
            )
        ]
