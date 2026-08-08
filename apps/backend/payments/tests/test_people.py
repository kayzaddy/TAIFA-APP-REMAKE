"""Phone-based identity + contacts: the address book behind pay-a-friend."""
from rest_framework.test import APITestCase

from ..models import Contact, Device


class TwoDeviceMixin:
    def register(self, device_id: str) -> dict:
        return self.client.post(
            "/api/v1/auth/device/register", {"device_id": device_id}, format="json"
        ).json()

    def as_device(self, reg: dict, device_id: str) -> None:
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}", HTTP_X_DEVICE_ID=device_id
        )

    def setUp(self):
        self.alice = self.register("dev-alice")
        self.bob = self.register("dev-bob")


class DeviceProfileTests(TwoDeviceMixin, APITestCase):
    def test_set_phone_and_display_name(self):
        self.as_device(self.alice, "dev-alice")
        resp = self.client.post(
            "/api/v1/auth/device/profile",
            {"phone_number": "+255 754 000 891", "display_name": "Alice N."},
            format="json",
        )
        self.assertEqual(resp.status_code, 200)
        body = resp.json()
        self.assertEqual(body["phone_number"], "+255754000891")
        self.assertEqual(body["display_name"], "Alice N.")

    def test_duplicate_phone_rejected(self):
        self.as_device(self.alice, "dev-alice")
        self.client.post(
            "/api/v1/auth/device/profile", {"phone_number": "+255700000001"}, format="json"
        )
        self.as_device(self.bob, "dev-bob")
        resp = self.client.post(
            "/api/v1/auth/device/profile", {"phone_number": "+255700000001"}, format="json"
        )
        self.assertEqual(resp.status_code, 409)

    def test_two_devices_with_blank_phone_do_not_collide(self):
        # Both alice and bob registered without ever setting a phone number —
        # must not trip the unique constraint against each other.
        self.assertIsNone(Device.objects.get(owner=self.alice["owner"]).phone_number)
        self.assertIsNone(Device.objects.get(owner=self.bob["owner"]).phone_number)


class PeopleLookupTests(TwoDeviceMixin, APITestCase):
    def setUp(self):
        super().setUp()
        self.as_device(self.bob, "dev-bob")
        self.client.post(
            "/api/v1/auth/device/profile",
            {"phone_number": "+255754000891", "display_name": "Bob K."},
            format="json",
        )

    def test_lookup_by_phone_variants(self):
        self.as_device(self.alice, "dev-alice")
        for variant in ["+255754000891", "255 754 000 891", "+255-754-000-891"]:
            resp = self.client.post(
                "/api/v1/payments/people/lookup", {"phone_number": variant}, format="json"
            )
            self.assertEqual(resp.status_code, 200, variant)
            self.assertEqual(resp.json()["owner"], self.bob["owner"])
            self.assertEqual(resp.json()["display_name"], "Bob K.")

    def test_lookup_unknown_number_404(self):
        self.as_device(self.alice, "dev-alice")
        resp = self.client.post(
            "/api/v1/payments/people/lookup", {"phone_number": "+255000000000"}, format="json"
        )
        self.assertEqual(resp.status_code, 404)

    def test_lookup_own_number_422(self):
        self.as_device(self.bob, "dev-bob")
        resp = self.client.post(
            "/api/v1/payments/people/lookup", {"phone_number": "+255754000891"}, format="json"
        )
        self.assertEqual(resp.status_code, 422)

    def test_leading_plus_via_raw_querystring_would_corrupt_a_get(self):
        """Documents *why* lookup is POST: a GET with '+' in the query string
        decodes it to a space (form-urlencoding), silently mangling E.164
        numbers. Confirms the number is stored with '+' intact so a naive
        GET-based lookup would in fact fail this exact case."""
        self.assertTrue(Device.objects.get(owner=self.bob["owner"]).phone_number.startswith("+"))


class MoneyRequestByPhoneTests(TwoDeviceMixin, APITestCase):
    def setUp(self):
        super().setUp()
        self.as_device(self.bob, "dev-bob")
        self.client.post(
            "/api/v1/auth/device/profile", {"phone_number": "+255754000891"}, format="json"
        )

    def test_request_money_by_phone(self):
        self.as_device(self.alice, "dev-alice")
        resp = self.client.post(
            "/api/v1/payments/requests",
            {"payer_phone": "+255754000891", "amount_minor": 500000, "currency": "TZS"},
            format="json",
        )
        self.assertEqual(resp.status_code, 201, resp.content)
        self.assertEqual(resp.json()["payer"], self.bob["owner"])

    def test_request_needs_payer_or_phone(self):
        self.as_device(self.alice, "dev-alice")
        resp = self.client.post(
            "/api/v1/payments/requests", {"amount_minor": 500000, "currency": "TZS"}, format="json"
        )
        self.assertEqual(resp.status_code, 400)

    def test_request_by_unknown_phone_404(self):
        self.as_device(self.alice, "dev-alice")
        resp = self.client.post(
            "/api/v1/payments/requests",
            {"payer_phone": "+255000000000", "amount_minor": 500000, "currency": "TZS"},
            format="json",
        )
        self.assertEqual(resp.status_code, 404)


class ContactTests(TwoDeviceMixin, APITestCase):
    def setUp(self):
        super().setUp()
        self.as_device(self.bob, "dev-bob")
        self.client.post(
            "/api/v1/auth/device/profile",
            {"phone_number": "+255754000891", "display_name": "Bob K."},
            format="json",
        )

    def test_save_and_list_contact(self):
        self.as_device(self.alice, "dev-alice")
        resp = self.client.post(
            "/api/v1/payments/contacts", {"phone_number": "+255754000891"}, format="json"
        )
        self.assertEqual(resp.status_code, 201, resp.content)
        self.assertEqual(resp.json()["contact_owner"], self.bob["owner"])
        self.assertEqual(resp.json()["display_name"], "Bob K.")

        listing = self.client.get("/api/v1/payments/contacts").json()
        self.assertEqual(len(listing["contacts"]), 1)

    def test_cannot_add_self(self):
        self.as_device(self.bob, "dev-bob")
        resp = self.client.post(
            "/api/v1/payments/contacts", {"phone_number": "+255754000891"}, format="json"
        )
        self.assertEqual(resp.status_code, 422)

    def test_re_adding_updates_not_duplicates(self):
        self.as_device(self.alice, "dev-alice")
        self.client.post("/api/v1/payments/contacts", {"phone_number": "+255754000891"}, format="json")
        self.client.post(
            "/api/v1/payments/contacts",
            {"phone_number": "+255754000891", "label": "Bestie"},
            format="json",
        )
        self.assertEqual(Contact.objects.filter(owner=self.alice["owner"]).count(), 1)
        self.assertEqual(
            Contact.objects.get(owner=self.alice["owner"]).display_name, "Bestie"
        )

    def test_favorite_and_delete(self):
        self.as_device(self.alice, "dev-alice")
        contact = self.client.post(
            "/api/v1/payments/contacts", {"phone_number": "+255754000891"}, format="json"
        ).json()
        resp = self.client.post(f"/api/v1/payments/contacts/{contact['id']}/favorite")
        self.assertTrue(resp.json()["favorite"])
        resp = self.client.delete(f"/api/v1/payments/contacts/{contact['id']}")
        self.assertEqual(resp.status_code, 204)
        self.assertEqual(Contact.objects.filter(owner=self.alice["owner"]).count(), 0)

    def test_strangers_cannot_delete_others_contacts(self):
        self.as_device(self.alice, "dev-alice")
        contact = self.client.post(
            "/api/v1/payments/contacts", {"phone_number": "+255754000891"}, format="json"
        ).json()
        self.as_device(self.bob, "dev-bob")
        resp = self.client.delete(f"/api/v1/payments/contacts/{contact['id']}")
        self.assertEqual(resp.status_code, 404)
