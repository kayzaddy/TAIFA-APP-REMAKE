from django.test import SimpleTestCase

from payments.money import Currency, Money


class MoneyTests(SimpleTestCase):
    def test_major_scales_into_minor_units(self):
        m = Money.major(2847500, Currency.TZS)
        self.assertEqual(m.minor_units, 284750000)

    def test_formats_tzs_without_decimals(self):
        self.assertEqual(Money.major(2847500, Currency.TZS).format(), "TSh 2,847,500")

    def test_formats_usd_with_two_decimals(self):
        self.assertEqual(Money.from_decimal(1140.5, Currency.USD).format(), "$ 1,140.50")

    def test_arithmetic_is_exact(self):
        a = Money.major(1000, Currency.TZS)
        b = Money.major(250, Currency.TZS)
        self.assertEqual(a - b, Money.major(750, Currency.TZS))
        self.assertEqual(a + b, Money.major(1250, Currency.TZS))

    def test_rejects_cross_currency(self):
        with self.assertRaises(ValueError):
            _ = Money.major(1, Currency.TZS) + Money.major(1, Currency.USD)

    def test_signed_formatting(self):
        self.assertEqual((-Money.major(500, Currency.TZS)).format(with_sign=True), "-TSh 500")
        self.assertEqual(Money.major(500, Currency.TZS).format(with_sign=True), "+TSh 500")
