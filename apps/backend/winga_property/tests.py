"""Winga Property Phase 1 tests."""
from __future__ import annotations

from django.core.management import call_command
from rest_framework.test import APITestCase

from winga_property.models import PropertyListing, PropertyVerificationStatus


class WingaPropertyApiTests(APITestCase):
    def setUp(self):
        call_command("seed_winga_property")
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "winga-property-test-1", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="winga-property-test-1",
        )
        self.owner = reg["owner"]
        self._grant_property_ops()

    def _grant_property_ops(self, write: bool = True) -> None:
        from enterprise.models import PlatformPrincipal, PlatformRole

        code = "property-ops-officer" if write else "property-ops-viewer"
        role = PlatformRole.objects.get(code=code)
        principal, _ = PlatformPrincipal.objects.get_or_create(
            principal_id=self.owner,
            defaults={"display_name": "Property Ops Test", "mfa_required": False},
        )
        principal.roles.add(role)

    def test_list_verified_listings(self):
        res = self.client.get("/api/v1/winga-property/listings", {"verified": "1"})
        self.assertEqual(res.status_code, 200)
        self.assertTrue(len(res.data) >= 1)
        self.assertEqual(res.data[0]["verification_status"], "verified")

    def test_search_by_region(self):
        res = self.client.get(
            "/api/v1/winga-property/listings",
            {"region": "Dar es Salaam", "q": "Masaki"},
        )
        self.assertEqual(res.status_code, 200)
        self.assertTrue(any("Masaki" in row["title"] for row in res.data))

    def test_map_pins(self):
        res = self.client.get("/api/v1/winga-property/map/pins")
        self.assertEqual(res.status_code, 200)
        self.assertTrue(len(res.data["pins"]) >= 1)

    def test_owner_create_listing_with_media_and_verify(self):
        self.client.post(
            "/api/v1/winga-property/owners/me",
            {"display_name": "Test Owner", "phone": "+255700000111"},
            format="json",
        )
        res = self.client.post(
            "/api/v1/winga-property/listings",
            {
                "category_code": "residential",
                "property_type_code": "apartment",
                "title": "Test Flat Ubungo",
                "price_minor": 900_000,
                "beds": 1,
                "baths": 1,
                "region": "Dar es Salaam",
                "district": "Ubungo",
                "latitude": "-6.7920",
                "longitude": "39.2080",
            },
            format="json",
        )
        self.assertEqual(res.status_code, 201)
        listing_id = res.data["id"]
        self.client.post(
            f"/api/v1/winga-property/listings/{listing_id}/media",
            {
                "kind": "photo",
                "url": "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800",
                "is_primary": True,
            },
            format="json",
        )
        sub = self.client.post(
            f"/api/v1/winga-property/listings/{listing_id}/submit-verification"
        )
        self.assertEqual(sub.status_code, 200)
        self.assertEqual(sub.data["verification_status"], "pending")
        verify = self.client.post(
            f"/api/v1/winga-property/listings/{listing_id}/verify",
            {"approve": True},
            format="json",
        )
        self.assertEqual(verify.status_code, 200)
        self.assertEqual(verify.data["verification_status"], "verified")

    def test_favorites_toggle(self):
        listing = PropertyListing.objects.filter(
            verification_status=PropertyVerificationStatus.VERIFIED
        ).first()
        res = self.client.post(
            "/api/v1/winga-property/favorites",
            {"listing_id": str(listing.id)},
            format="json",
        )
        self.assertEqual(res.status_code, 200)
        self.assertTrue(res.data["favorited"])
        favs = self.client.get("/api/v1/winga-property/favorites")
        self.assertEqual(len(favs.data), 1)

    def test_saved_search(self):
        res = self.client.post(
            "/api/v1/winga-property/saved-searches",
            {"name": "Masaki 2-bed", "filters": {"region": "Dar es Salaam", "beds": 2}},
            format="json",
        )
        self.assertEqual(res.status_code, 201)
        listed = self.client.get("/api/v1/winga-property/saved-searches")
        self.assertEqual(len(listed.data), 1)

    def test_neighborhood_intelligence(self):
        listing = PropertyListing.objects.filter(
            verification_status=PropertyVerificationStatus.VERIFIED
        ).first()
        res = self.client.get(
            f"/api/v1/winga-property/listings/{listing.id}/intelligence"
        )
        self.assertEqual(res.status_code, 200)
        self.assertIn("nearby", res.data)
        self.assertIn("safety_score_e4", res.data)

    def test_visit_score_and_commute(self):
        listing = PropertyListing.objects.filter(
            verification_status=PropertyVerificationStatus.VERIFIED
        ).first()
        visit = self.client.get(
            f"/api/v1/winga-property/listings/{listing.id}/visit-score",
            {"dest_lat": "-6.7920", "dest_lng": "39.2080"},
        )
        self.assertEqual(visit.status_code, 200)
        self.assertGreaterEqual(visit.data["stars"], 1)
        commute = self.client.get(
            f"/api/v1/winga-property/listings/{listing.id}/commute",
            {"dest_lat": "-6.7920", "dest_lng": "39.2080"},
        )
        self.assertEqual(commute.status_code, 200)
        self.assertIn("duration_seconds", commute.data)

    def test_ai_search_and_recommendations(self):
        ai = self.client.post(
            "/api/v1/winga-property/discovery/ai-search",
            {"query": "2 bed apartment Masaki rent"},
            format="json",
        )
        self.assertEqual(ai.status_code, 200)
        self.assertIn("listings", ai.data)
        rec = self.client.get("/api/v1/winga-property/discovery/recommendations")
        self.assertEqual(rec.status_code, 200)

    def test_recently_viewed_and_compare(self):
        listing = PropertyListing.objects.filter(
            verification_status=PropertyVerificationStatus.VERIFIED
        ).first()
        self.client.get(f"/api/v1/winga-property/listings/{listing.id}")
        recent = self.client.get("/api/v1/winga-property/discovery/recently-viewed")
        self.assertEqual(recent.status_code, 200)
        self.assertTrue(len(recent.data) >= 1)
        other = PropertyListing.objects.filter(
            verification_status=PropertyVerificationStatus.VERIFIED
        ).exclude(id=listing.id).first()
        ids = [str(listing.id)]
        if other:
            ids.append(str(other.id))
        cmp_res = self.client.post(
            "/api/v1/winga-property/discovery/compare",
            {"listing_ids": ids},
            format="json",
        )
        self.assertEqual(cmp_res.status_code, 200)
        self.assertEqual(cmp_res.data["count"], len(ids))

    def test_map_clusters_and_advanced_search(self):
        clusters = self.client.get("/api/v1/winga-property/map/clusters")
        self.assertEqual(clusters.status_code, 200)
        self.assertIn("clusters", clusters.data)
        adv = self.client.get(
            "/api/v1/winga-property/discovery/search",
            {"region": "Dar es Salaam", "min_safety_e4": "6000"},
        )
        self.assertEqual(adv.status_code, 200)

    def test_listing_experience_walkthrough(self):
        listing = PropertyListing.objects.filter(
            verification_status=PropertyVerificationStatus.VERIFIED
        ).first()
        res = self.client.get(f"/api/v1/winga-property/listings/{listing.id}/experience")
        self.assertEqual(res.status_code, 200)
        self.assertIn("gallery", res.data)
        self.assertIn("walkthrough", res.data)

    def test_viewing_pass_create_pay_and_unlock(self):
        listing = PropertyListing.objects.filter(
            verification_status=PropertyVerificationStatus.VERIFIED
        ).first()
        detail = self.client.get(f"/api/v1/winga-property/listings/{listing.id}")
        self.assertFalse(detail.data["is_unlocked"])
        created = self.client.post(
            "/api/v1/winga-property/viewing-pass",
            {"plan_code": "single", "listing_id": str(listing.id)},
            format="json",
        )
        self.assertEqual(created.status_code, 201)
        pass_id = created.data["id"]
        paid = self.client.post(
            f"/api/v1/winga-property/viewing-pass/{pass_id}/pay",
            {},
            format="json",
            HTTP_IDEMPOTENCY_KEY="wp-pass-pay-1",
        )
        self.assertEqual(paid.status_code, 200)
        self.assertEqual(paid.data["status"], "active")
        self.assertTrue(paid.data["qr_token"])
        unlocked = self.client.get(f"/api/v1/winga-property/listings/{listing.id}")
        self.assertTrue(unlocked.data["is_unlocked"])
        verify = self.client.post(
            "/api/v1/winga-property/viewing-pass/verify",
            {"qr_token": paid.data["qr_token"]},
            format="json",
        )
        self.assertTrue(verify.data["valid"])

    def test_live_session_lifecycle(self):
        listing = PropertyListing.objects.filter(
            verification_status=PropertyVerificationStatus.VERIFIED
        ).first()
        created = self.client.post(
            f"/api/v1/winga-property/listings/{listing.id}/live-sessions",
            {"notes": "Can I see the kitchen?"},
            format="json",
        )
        self.assertEqual(created.status_code, 201)
        session_id = created.data["id"]
        joined = self.client.post(
            f"/api/v1/winga-property/live-sessions/{session_id}/join"
        )
        self.assertEqual(joined.status_code, 200)
        self.assertEqual(joined.data["status"], "live")
        msg = self.client.post(
            f"/api/v1/winga-property/live-sessions/{session_id}/messages",
            {"body": "Is the water tank on the roof?"},
            format="json",
        )
        self.assertEqual(msg.status_code, 201)
        ended = self.client.post(f"/api/v1/winga-property/live-sessions/{session_id}/end")
        self.assertEqual(ended.status_code, 200)
        self.assertEqual(ended.data["status"], "ended")
        self.assertIn("ai_transcript", ended.data)

    def test_copilot_and_rankings(self):
        listing = PropertyListing.objects.filter(
            verification_status=PropertyVerificationStatus.VERIFIED
        ).first()
        copilot = self.client.post(
            "/api/v1/winga-property/copilot/chat",
            {"query": "Is this good for a family?", "listing_id": str(listing.id)},
            format="json",
        )
        self.assertEqual(copilot.status_code, 200)
        self.assertIn("answer", copilot.data)
        self.assertFalse(copilot.data.get("payment_authorized", True))
        rank = self.client.get(
            "/api/v1/winga-property/copilot/rankings",
            {"listing_ids": str(listing.id)},
        )
        self.assertEqual(rank.status_code, 200)
        self.assertTrue(len(rank.data["rankings"]) >= 1)

    def test_assign_winga_crm_flow(self):
        listing = PropertyListing.objects.filter(
            verification_status=PropertyVerificationStatus.VERIFIED
        ).first()
        wingas = self.client.get("/api/v1/winga-property/wingas")
        self.assertEqual(wingas.status_code, 200)
        self.assertTrue(len(wingas.data["wingas"]) >= 1)
        assigned = self.client.post(
            f"/api/v1/winga-property/listings/{listing.id}/assign-winga",
            {"notes": "Need help negotiating"},
            format="json",
        )
        self.assertEqual(assigned.status_code, 201)
        aid = assigned.data["id"]
        chat = self.client.post(
            f"/api/v1/winga-property/assignments/{aid}/chat",
            {"text": "Can we view this Saturday?"},
            format="json",
        )
        self.assertEqual(chat.status_code, 201)
        doc = self.client.post(
            f"/api/v1/winga-property/assignments/{aid}/documents",
            {
                "title": "Tenant application form",
                "url": "https://example.com/form.pdf",
            },
            format="json",
        )
        self.assertEqual(doc.status_code, 201)
        commission = self.client.get(
            f"/api/v1/winga-property/assignments/{aid}/commission-preview"
        )
        self.assertEqual(commission.status_code, 200)
        self.assertIn("commission_minor", commission.data)

    def test_rental_application_lease_and_payment_flow(self):
        listing = PropertyListing.objects.filter(
            verification_status=PropertyVerificationStatus.VERIFIED
        ).first()
        income = max(listing.price_minor * 4, 1_000_000)
        created = self.client.post(
            f"/api/v1/winga-property/listings/{listing.id}/applications",
            {
                "employment_status": "employed",
                "monthly_income_minor": income,
                "national_id": "19900101-12345-00001-12",
                "notes": "Ready to move in",
            },
            format="json",
        )
        self.assertEqual(created.status_code, 201)
        app_id = created.data["id"]
        doc = self.client.post(
            f"/api/v1/winga-property/applications/{app_id}/documents",
            {
                "kind": "payslip",
                "title": "March payslip",
                "url": "https://example.com/payslip.pdf",
            },
            format="json",
        )
        self.assertEqual(doc.status_code, 201)
        submitted = self.client.post(f"/api/v1/winga-property/applications/{app_id}/submit")
        self.assertEqual(submitted.status_code, 200)
        self.assertEqual(submitted.data["status"], "under_review")
        identity = self.client.post(
            f"/api/v1/winga-property/applications/{app_id}/verify-identity"
        )
        self.assertEqual(identity.status_code, 200)
        self.assertEqual(identity.data["status"], "verified")
        income_check = self.client.post(
            f"/api/v1/winga-property/applications/{app_id}/verify-income"
        )
        self.assertEqual(income_check.status_code, 200)
        self.assertEqual(income_check.data["status"], "verified")
        approved = self.client.post(f"/api/v1/winga-property/applications/{app_id}/approve")
        self.assertEqual(approved.status_code, 200)
        self.assertEqual(approved.data["status"], "approved")
        lease_res = self.client.post(
            f"/api/v1/winga-property/applications/{app_id}/generate-lease"
        )
        self.assertEqual(lease_res.status_code, 201)
        lease_id = lease_res.data["id"]
        tenant_sign = self.client.post(f"/api/v1/winga-property/leases/{lease_id}/sign")
        self.assertEqual(tenant_sign.status_code, 200)
        from winga_property import transactions as transactions_svc
        from winga_property.models import PropertyLease

        lease = PropertyLease.objects.get(pk=lease_id)
        transactions_svc.sign_lease(lease=lease, actor=lease.owner_principal)
        lease_detail = self.client.get(f"/api/v1/winga-property/leases/{lease_id}")
        self.assertEqual(lease_detail.status_code, 200)
        self.assertEqual(lease_detail.data["status"], "active")
        deposit = next(p for p in lease_detail.data["payments"] if p["kind"] == "deposit")
        paid = self.client.post(
            f"/api/v1/winga-property/lease-payments/{deposit['id']}/pay",
            {},
            format="json",
            HTTP_IDEMPOTENCY_KEY="lease-deposit-pay-1",
        )
        self.assertEqual(paid.status_code, 200)
        self.assertEqual(paid.data["status"], "paid")
        move = lease_detail.data["move_workflows"][0]
        completed = self.client.post(
            f"/api/v1/winga-property/move-workflows/{move['id']}/complete"
        )
        self.assertEqual(completed.status_code, 200)
        self.assertEqual(completed.data["status"], "completed")
        renewed = self.client.post(f"/api/v1/winga-property/leases/{lease_id}/renew")
        self.assertEqual(renewed.status_code, 200)
        self.assertTrue(any(p["kind"] == "renewal" for p in renewed.data["payments"]))

    def test_ops_dashboard_moderation_and_disputes(self):
        listing = PropertyListing.objects.filter(
            verification_status=PropertyVerificationStatus.VERIFIED
        ).first()
        report = self.client.post(
            f"/api/v1/winga-property/listings/{listing.id}/report",
            {"reason": "misleading", "notes": "Photos do not match"},
            format="json",
        )
        self.assertEqual(report.status_code, 201)
        fraud = self.client.get(f"/api/v1/winga-property/listings/{listing.id}/fraud-signals")
        self.assertEqual(fraud.status_code, 200)
        self.assertIn("signals", fraud.data)
        self.assertIn("ml", fraud.data)
        self.assertFalse(fraud.data.get("payment_authorized", True))
        console = self.client.get("/api/v1/winga-property/ops/console")
        self.assertEqual(console.status_code, 200)
        self.assertIn("dashboard", console.data)
        self.assertIn("moderation", console.data)
        dashboard = self.client.get("/api/v1/winga-property/ops/dashboard")
        self.assertEqual(dashboard.status_code, 200)
        self.assertGreaterEqual(dashboard.data["moderation_pending"], 1)
        queue = self.client.get("/api/v1/winga-property/ops/moderation-queue")
        self.assertEqual(queue.status_code, 200)
        self.assertTrue(len(queue.data["reports"]) >= 1)
        resolved = self.client.post(
            f"/api/v1/winga-property/ops/moderation/{report.data['id']}/resolve",
            {"action": "dismiss", "notes": "No violation found"},
            format="json",
        )
        self.assertEqual(resolved.status_code, 200)
        dispute = self.client.post(
            "/api/v1/winga-property/ops/disputes",
            {
                "subject_type": "listing",
                "subject_id": str(listing.id),
                "reason": "Deposit not returned",
            },
            format="json",
        )
        self.assertEqual(dispute.status_code, 201)
        did = dispute.data["id"]
        assigned = self.client.post(
            f"/api/v1/winga-property/ops/disputes/{did}/assign",
            {"ops_principal": "ops-agent-1"},
            format="json",
        )
        self.assertEqual(assigned.status_code, 200)
        self.assertEqual(assigned.data["status"], "investigating")
        closed = self.client.post(
            f"/api/v1/winga-property/ops/disputes/{did}/resolve",
            {"resolution": "Owner agreed to refund", "approve": True},
            format="json",
        )
        self.assertEqual(closed.status_code, 200)
        self.assertEqual(closed.data["status"], "resolved")
        analytics = self.client.get("/api/v1/winga-property/ops/analytics")
        self.assertEqual(analytics.status_code, 200)
        self.assertIn("conversion_funnel", analytics.data)

    def test_ops_rbac_denies_without_role(self):
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "winga-property-no-ops", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="winga-property-no-ops",
        )
        denied = self.client.get("/api/v1/winga-property/ops/dashboard")
        self.assertEqual(denied.status_code, 403)
