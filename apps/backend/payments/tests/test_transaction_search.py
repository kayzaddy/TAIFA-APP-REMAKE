"""Transaction search/filtering: GET /api/v1/payments/transactions."""
from rest_framework.test import APITestCase


class TransactionSearchTests(APITestCase):
    def setUp(self):
        reg = self.client.post(
            "/api/v1/auth/device/register", {"device_id": "dev-search-1"}, format="json"
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}", HTTP_X_DEVICE_ID="dev-search-1"
        )
        self.owner = reg["owner"]

        # Opening balance gives one top_up transaction; add a few more.
        for i, (amount, note) in enumerate(
            [(1000000, "Lunch with Bob"), (2000000, "Rent"), (500000, "Coffee")]
        ):
            self.client.post(
                "/api/v1/payments/topups",
                {"amount_minor": amount, "currency": "TZS", "msisdn": "+255754000891", "note": note},
                format="json",
                HTTP_IDEMPOTENCY_KEY=f"search-topup-{i}",
            )

    def test_unfiltered_search_returns_all_with_pagination_metadata(self):
        resp = self.client.get("/api/v1/payments/transactions")
        body = resp.json()
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(body["count"], 4)  # opening balance + 3 top-ups
        self.assertEqual(body["page"], 1)
        self.assertEqual(len(body["results"]), 4)

    def test_filter_by_type(self):
        # The opening balance is itself recorded as a top_up, so all 4 match.
        resp = self.client.get("/api/v1/payments/transactions?type=top_up")
        body = resp.json()
        self.assertEqual(body["count"], 4)
        self.assertTrue(all(t["type"] == "top_up" for t in body["results"]))

    def test_filter_by_amount_range(self):
        resp = self.client.get(
            "/api/v1/payments/transactions?min_amount_minor=800000&max_amount_minor=1500000"
        )
        body = resp.json()
        self.assertEqual(body["count"], 1)
        self.assertEqual(body["results"][0]["amount_minor"], 1000000)

    def test_free_text_search_on_note(self):
        resp = self.client.get("/api/v1/payments/transactions?q=lunch")
        body = resp.json()
        self.assertEqual(body["count"], 1)
        self.assertIn("Lunch", body["results"][0]["note"])

    def test_free_text_search_no_match(self):
        resp = self.client.get("/api/v1/payments/transactions?q=nonexistent")
        self.assertEqual(resp.json()["count"], 0)

    def test_pagination(self):
        resp = self.client.get("/api/v1/payments/transactions?page_size=2&page=1")
        body = resp.json()
        self.assertEqual(len(body["results"]), 2)
        self.assertEqual(body["num_pages"], 2)
        resp2 = self.client.get("/api/v1/payments/transactions?page_size=2&page=2")
        self.assertEqual(len(resp2.json()["results"]), 2)

    def test_invalid_range_rejected(self):
        resp = self.client.get(
            "/api/v1/payments/transactions?min_amount_minor=5000&max_amount_minor=1000"
        )
        self.assertEqual(resp.status_code, 400)

    def test_scoped_to_authenticated_owner_only(self):
        other = self.client.post(
            "/api/v1/auth/device/register", {"device_id": "dev-search-2"}, format="json"
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {other['token']}", HTTP_X_DEVICE_ID="dev-search-2"
        )
        resp = self.client.get("/api/v1/payments/transactions")
        self.assertEqual(resp.json()["count"], 1)  # only their own opening balance

    def test_requires_auth(self):
        self.client.credentials()
        resp = self.client.get("/api/v1/payments/transactions")
        self.assertEqual(resp.status_code, 401)
