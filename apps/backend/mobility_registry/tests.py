from datetime import timedelta

from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APITestCase

from enterprise.models import PlatformPrincipal, PlatformRole
from trips.models import Driver, DriverStatus

from .crypto import blind_index, decrypt_bytes, encrypt_text
from .models import (
    ApplicationStatus,
    ApplicationType,
    DocumentStatus,
    DriverRegistration,
    RegistryApplication,
    RegistryDocument,
    VerificationStage,
)
from .services import ActorContext, RegistryError, create_application, submit_application
from .tasks import monitor_document_expiry


class RegistryCryptoTests(TestCase):
    def test_encryption_authenticates_context_and_blind_index_is_stable(self):
        encrypted = encrypt_text("19900101-12345-00001-12", context="national-id:test")
        plaintext = decrypt_bytes(
            encrypted.ciphertext,
            encrypted.nonce,
            key_version=encrypted.key_version,
            context="national-id:test",
        )
        self.assertEqual(plaintext.decode(), "19900101-12345-00001-12")
        self.assertEqual(blind_index(" AB 123 "), blind_index("ab123"))
        with self.assertRaises(Exception):
            decrypt_bytes(
                encrypted.ciphertext,
                encrypted.nonce,
                key_version=encrypted.key_version,
                context="wrong-context",
            )


class RegistryApiTests(APITestCase):
    required_driver_documents = [
        "national_id",
        "driving_license",
        "passport_photo",
        "selfie_verification",
        "vehicle_permit",
        "good_conduct",
    ]

    def setUp(self):
        applicant = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "registry-applicant", "platform": "test"},
            format="json",
        ).json()
        self.applicant_owner = applicant["owner"]
        self.applicant_headers = {
            "HTTP_AUTHORIZATION": f"Bearer {applicant['token']}",
            "HTTP_X_DEVICE_ID": "registry-applicant",
        }

        officer = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "registry-officer", "platform": "test"},
            format="json",
        ).json()
        self.officer_owner = officer["owner"]
        self.officer_headers = {
            "HTTP_AUTHORIZATION": f"Bearer {officer['token']}",
            "HTTP_X_DEVICE_ID": "registry-officer",
        }
        role = PlatformRole.objects.get(code="compliance-officer")
        principal = PlatformPrincipal.objects.create(
            principal_id=self.officer_owner,
            display_name="National Compliance Officer",
            attributes={"regions": ["Dar es Salaam"]},
        )
        principal.roles.add(role)

    def _register_driver(self):
        response = self.client.post(
            "/api/v1/mobility-registry/applications/drivers",
            {
                "client_reference": "offline-driver-001",
                "full_name": "Asha Mussa",
                "national_id_number": "19900101-12345-00001-12",
                "phone_number": "+255712345678",
                "email": "asha@example.test",
                "gender": "female",
                "date_of_birth": "1990-01-01",
                "nationality": "Tanzanian",
                "region": "Dar es Salaam",
                "district": "Kinondoni",
                "ward": "Mwenge",
                "street": "Sam Nujoma Road",
                "postal_address": "P.O. Box 1",
                "emergency_contact_name": "Mussa Juma",
                "emergency_contact_phone": "+255713000000",
                "preferred_language": "sw",
                "wallet_account_ref": self.applicant_owner,
            },
            format="json",
            **self.applicant_headers,
        )
        self.assertEqual(response.status_code, 201, response.content)
        return response.json()["id"]

    def _upload_documents(self, application_id):
        document_ids = []
        for index, kind in enumerate(self.required_driver_documents):
            payload = f"%PDF-1.4 registry-{kind}".encode()
            response = self.client.post(
                f"/api/v1/mobility-registry/applications/{application_id}/documents/upload",
                {
                    "kind": kind,
                    "document": SimpleUploadedFile(
                        f"{kind}.pdf",
                        payload,
                        content_type="application/pdf",
                    ),
                    "document_number": f"DOC-{index}",
                    "issue_date": str(timezone.localdate() - timedelta(days=30)),
                    "expiry_date": str(timezone.localdate() + timedelta(days=365)),
                },
                format="multipart",
                **self.applicant_headers,
            )
            self.assertEqual(response.status_code, 201, response.content)
            document_ids.append(response.json()["id"])
        return document_ids

    def _approve_driver(self):
        application_id = self._register_driver()
        document_ids = self._upload_documents(application_id)
        submitted = self.client.post(
            f"/api/v1/mobility-registry/applications/{application_id}/submit",
            {},
            format="json",
            **self.applicant_headers,
        )
        self.assertEqual(submitted.status_code, 200, submitted.content)
        self.assertEqual(submitted.json()["status"], ApplicationStatus.SUBMITTED)
        for document_id in document_ids:
            reviewed = self.client.post(
                f"/api/v1/mobility-registry/documents/{document_id}/review",
                {"decision": DocumentStatus.VERIFIED},
                format="json",
                **self.officer_headers,
            )
            self.assertEqual(reviewed.status_code, 200, reviewed.content)
        for _ in range(3):
            advanced = self.client.post(
                f"/api/v1/mobility-registry/applications/{application_id}/workflow/advance",
                {"comments": "validated"},
                format="json",
                **self.officer_headers,
            )
            self.assertEqual(advanced.status_code, 200, advanced.content)
        self.assertEqual(advanced.json()["stage"], VerificationStage.APPROVAL)
        approved = self.client.post(
            f"/api/v1/mobility-registry/applications/{application_id}/workflow/approve",
            {"comments": "all national requirements satisfied"},
            format="json",
            **self.officer_headers,
        )
        self.assertEqual(approved.status_code, 200, approved.content)
        return RegistryApplication.objects.get(pk=application_id)

    def test_full_driver_registration_document_review_and_approval(self):
        application = self._approve_driver()
        self.assertEqual(application.status, ApplicationStatus.APPROVED)
        self.assertTrue(application.approval_reference)
        driver = Driver.objects.get(pk=application.operational_object_id)
        self.assertEqual(driver.status, DriverStatus.ACTIVE)
        self.assertEqual(driver.registry_approval_id, application.id)
        self.assertNotIn(
            "national_id_number",
            self.client.get(
                f"/api/v1/mobility-registry/applications/{application.id}",
                **self.applicant_headers,
            ).json(),
        )

    def test_applicant_cannot_review_own_document(self):
        application_id = self._register_driver()
        document_id = self._upload_documents(application_id)[0]
        response = self.client.post(
            f"/api/v1/mobility-registry/documents/{document_id}/review",
            {"decision": DocumentStatus.VERIFIED},
            format="json",
            **self.applicant_headers,
        )
        self.assertEqual(response.status_code, 403)

    def test_document_round_trip_is_encrypted_and_audited(self):
        application_id = self._register_driver()
        document_id = self._upload_documents(application_id)[0]
        document = RegistryDocument.objects.get(pk=document_id)
        self.assertNotIn(b"registry-national_id", bytes(document.encrypted_payload))
        response = self.client.get(
            f"/api/v1/mobility-registry/documents/{document_id}/download",
            **self.applicant_headers,
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.content, b"%PDF-1.4 registry-national_id")

    def test_expired_required_document_suspends_approved_driver(self):
        application = self._approve_driver()
        RegistryDocument.objects.filter(
            application=application,
            kind="driving_license",
            current=True,
        ).update(expiry_date=timezone.localdate() - timedelta(days=1))
        result = monitor_document_expiry()
        application.refresh_from_db()
        driver = Driver.objects.get(pk=application.operational_object_id)
        self.assertEqual(result["suspended"], 1)
        self.assertEqual(application.status, ApplicationStatus.SUSPENDED)
        self.assertEqual(driver.status, DriverStatus.SUSPENDED)

    def test_queue_and_search_require_compliance_role(self):
        application_id = self._register_driver()
        denied = self.client.get(
            "/api/v1/mobility-registry/verification/dashboard",
            **self.applicant_headers,
        )
        self.assertEqual(denied.status_code, 403)
        dashboard = self.client.get(
            "/api/v1/mobility-registry/verification/dashboard",
            **self.officer_headers,
        )
        self.assertEqual(dashboard.status_code, 200)
        result = self.client.get(
            "/api/v1/mobility-registry/search",
            {"q": "Asha", "field": "name"},
            **self.officer_headers,
        )
        self.assertEqual(result.status_code, 200)
        self.assertEqual(result.json()[0]["application"]["id"], application_id)

    def test_vehicle_station_and_fleet_registration(self):
        vehicle = self.client.post(
            "/api/v1/mobility-registry/applications/vehicles",
            {
                "client_reference": "vehicle-1",
                "mode": "motorcycle",
                "registration_number": "T 123 ABC",
                "chassis_number": "CHASSIS-123",
                "engine_number": "ENGINE-123",
                "make": "TVS",
                "model": "HLX",
                "year": 2024,
                "fuel_type": "petrol",
                "color": "blue",
                "capacity": 2,
                "region": "Dar es Salaam",
                "district": "Kinondoni",
            },
            format="json",
            **self.applicant_headers,
        )
        self.assertEqual(vehicle.status_code, 201, vehicle.content)
        station = self.client.post(
            "/api/v1/mobility-registry/applications/stations",
            {
                "client_reference": "station-1",
                "name": "Mwenge Station",
                "code": "mwenge-registry",
                "latitude": "-6.770000",
                "longitude": "39.220000",
                "region": "Dar es Salaam",
                "district": "Kinondoni",
                "ward": "Mwenge",
                "street": "Sam Nujoma",
                "phone_number": "+255710000000",
                "operating_hours": {"opens": "06:00", "closes": "23:00"},
                "capacity": 200,
            },
            format="json",
            **self.applicant_headers,
        )
        self.assertEqual(station.status_code, 201, station.content)
        fleet = self.client.post(
            "/api/v1/mobility-registry/applications/fleets",
            {
                "client_reference": "fleet-1",
                "fleet_type": "business",
                "business_name": "Taifa Transport Company",
                "brela_number": "BRELA-123",
                "tin": "TIN-123",
                "business_license_number": "BL-123",
                "address": "Dar es Salaam",
                "declared_fleet_size": 50,
                "region": "Dar es Salaam",
                "district": "Kinondoni",
            },
            format="json",
            **self.applicant_headers,
        )
        self.assertEqual(fleet.status_code, 201, fleet.content)

    def test_blacklisting_immediately_suspends_approved_participant(self):
        application = self._approve_driver()
        response = self.client.post(
            "/api/v1/mobility-registry/compliance/blacklist",
            {
                "identifier_type": "national_id",
                "identifier": "19900101-12345-00001-12",
                "reason": "confirmed identity fraud",
            },
            format="json",
            **self.officer_headers,
        )
        self.assertEqual(response.status_code, 201, response.content)
        application.refresh_from_db()
        driver = Driver.objects.get(pk=application.operational_object_id)
        self.assertEqual(application.status, ApplicationStatus.SUSPENDED)
        self.assertEqual(driver.status, DriverStatus.SUSPENDED)


class RegistryWorkflowUnitTests(TestCase):
    def test_submission_records_missing_documents(self):
        application = create_application(
            application_type=ApplicationType.DRIVER,
            applicant_principal="driver-owner",
            client_reference="offline-1",
            region="Dodoma",
            district="Dodoma Urban",
        )
        encrypted = encrypt_text("NIDA-1", context=f"registry-driver-national-id:{application.id}")
        phone = encrypt_text("+255700000000", context=f"registry-driver-phone:{application.id}")
        emergency = encrypt_text(
            "+255711111111",
            context=f"registry-driver-emergency-phone:{application.id}",
        )
        DriverRegistration.objects.create(
            application=application,
            full_name="Juma Test",
            pii_key_version=encrypted.key_version,
            national_id_ciphertext=encrypted.ciphertext,
            national_id_nonce=encrypted.nonce,
            national_id_hash=blind_index("NIDA-1"),
            national_id_masked="**A-1",
            phone_ciphertext=phone.ciphertext,
            phone_nonce=phone.nonce,
            phone_hash=blind_index("+255700000000"),
            phone_masked="********0000",
            gender="male",
            date_of_birth=timezone.localdate() - timedelta(days=30 * 365),
            emergency_contact_name="Contact",
            emergency_phone_ciphertext=emergency.ciphertext,
            emergency_phone_nonce=emergency.nonce,
            emergency_phone_masked="********1111",
            wallet_account_ref="driver-owner",
        )
        submitted = submit_application(
            application.id,
            actor=ActorContext(principal="driver-owner"),
        )
        self.assertEqual(submitted.status, ApplicationStatus.DOCUMENTS_MISSING)
        self.assertEqual(submitted.transitions.count(), 1)
