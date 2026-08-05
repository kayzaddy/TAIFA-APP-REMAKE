"""Digital Ecosystem Platform tests."""
from __future__ import annotations

from django.test import TestCase

from enterprise.models import WorkflowDefinition, WorkflowInstance

from .ai import invoke_ai
from .models import (
    AgricultureFarm,
    AiCapability,
    IndustryDomain,
    SharedService,
    SuperAppModule,
    WebhookSubscription,
)
from .services import (
    PlatformError,
    create_agriculture_listing,
    ecosystem_blueprint,
    list_enabled_modules,
    register_farm,
    seed_ecosystem_catalog,
    set_module_enabled,
    start_ecosystem_workflow,
)


class EcosystemCatalogTests(TestCase):
    def test_seed_creates_ten_domains_and_shared_services(self):
        result = seed_ecosystem_catalog()
        self.assertEqual(result["domains"], 10)
        self.assertGreaterEqual(result["shared_services"], 14)
        self.assertTrue(IndustryDomain.objects.filter(code="mobility").exists())
        self.assertTrue(IndustryDomain.objects.filter(code="agriculture").exists())
        self.assertTrue(SharedService.objects.filter(code="payments").exists())
        self.assertTrue(SharedService.objects.filter(code="identity").exists())
        self.assertTrue(SuperAppModule.objects.filter(code="wallet").exists())
        blueprint = ecosystem_blueprint()
        self.assertEqual(blueprint["model_version"], "ecosystem-blueprint-v1")
        self.assertIn("rest", blueprint["open_platform"])


class SuperAppEnablementTests(TestCase):
    def setUp(self):
        seed_ecosystem_catalog()

    def test_default_and_toggle_modules(self):
        modules = list_enabled_modules(principal="user-1")
        by_code = {m["code"]: m for m in modules}
        self.assertTrue(by_code["wallet"]["enabled"])
        self.assertFalse(by_code["agriculture"]["enabled"])
        set_module_enabled(principal="user-1", module_code="agriculture", enabled=True)
        modules = list_enabled_modules(principal="user-1")
        by_code = {m["code"]: m for m in modules}
        self.assertTrue(by_code["agriculture"]["enabled"])
        with self.assertRaises(PlatformError):
            set_module_enabled(principal="user-1", module_code="nope", enabled=True)


class EcosystemWorkflowTests(TestCase):
    def setUp(self):
        seed_ecosystem_catalog()

    def test_start_and_advance_merchant_approval(self):
        self.assertTrue(
            WorkflowDefinition.objects.filter(code="ecosystem.merchant_approval").exists()
        )
        inst = start_ecosystem_workflow(
            binding_code="merchant_approval",
            resource_id="merchant-99",
            actor="ops-1",
        )
        self.assertEqual(inst.status, "running")
        from enterprise import workflow as wf

        while inst.status == "running":
            inst = wf.advance(instance_id=inst.id, actor="ops-1", note="ok")
        self.assertEqual(inst.status, "completed")
        self.assertEqual(WorkflowInstance.objects.filter(pk=inst.id).count(), 1)


class AiAndOpenPlatformTests(TestCase):
    def setUp(self):
        seed_ecosystem_catalog()

    def test_invoke_recommendations(self):
        self.assertTrue(AiCapability.objects.filter(code="recommendations").exists())
        result = invoke_ai(
            capability_code="recommendations",
            principal="user-ai",
            payload={},
            domain_code="commerce",
        )
        self.assertIn(result.get("capability"), {"recommendations", "recommendation"})
        body = result.get("result") or result
        self.assertTrue(
            "items" in body
            or "items" in (body.get("result") or {})
            or result.get("decision_id")
        )

    def test_webhook_secret_hashed(self):
        sub, raw = WebhookSubscription.issue(
            owner_principal="partner-1",
            target_url="https://example.com/hooks/taifa",
            event_types=["*"],
        )
        self.assertTrue(raw)
        self.assertEqual(sub.secret_hash, WebhookSubscription.hash_secret(raw))
        self.assertNotEqual(sub.secret_hash, raw)


class AgricultureDomainTests(TestCase):
    def test_farm_and_listing(self):
        farm = register_farm(
            owner="farmer-1",
            farm_code="farm-mbeya-1",
            name="Mbeya Highlands",
            region="Mbeya",
            crop_types=["maize", "avocado"],
        )
        self.assertEqual(AgricultureFarm.objects.count(), 1)
        listing = create_agriculture_listing(
            owner="farmer-1",
            kind="produce",
            title="Avocado grade A",
            price_minor=250_000,
            quantity_e2=100_00,
            region="Mbeya",
            farm_id=farm.id,
        )
        self.assertEqual(listing.status, "open")
        self.assertEqual(listing.payment_ref, "")
