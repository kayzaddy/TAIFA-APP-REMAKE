from django.test import SimpleTestCase

from payments.gateways.base import (
    PaymentContractError,
    PaymentOperation,
    PaymentProvider,
    PaymentRequest,
)
from payments.money import Currency, Money

from .fakes import build_test_router


class RouterTests(SimpleTestCase):
    def setUp(self):
        self.router = build_test_router()

    def _req(self, amount, operator="mpesa"):
        return PaymentRequest(
            idempotency_key="k", reference="r", amount=amount,
            operation=PaymentOperation.PAYOUT, method_kind="mobile_money",
            method_ref="+255700000000", operator=operator,
        )

    def test_routes_mpesa_to_mpesa(self):
        gw = self.router.resolve(self._req(Money.major(50000, Currency.TZS)))
        self.assertEqual(gw.provider, PaymentProvider.MPESA)

    def test_falls_back_to_selcom_over_limit(self):
        gw = self.router.resolve(self._req(Money.major(25_000_000, Currency.TZS)))
        self.assertEqual(gw.provider, PaymentProvider.SELCOM)

    def test_unsupported_currency_raises(self):
        with self.assertRaises(PaymentContractError):
            self.router.resolve(self._req(Money.major(1000, Currency.UGX)))
